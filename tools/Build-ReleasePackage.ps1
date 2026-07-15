[CmdletBinding()]
param(
    [string]$OutputDirectory = '',
    [switch]$SkipArchive,
    [switch]$OpenOutput
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$ToolboxRoot = Split-Path -Parent $PSScriptRoot

$ExeBuildScript = Join-Path $PSScriptRoot 'Build-CkToolboxExe.ps1'
$Utf8Bom = New-Object System.Text.UTF8Encoding($true)
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $ToolboxRoot 'dist'
}
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)

function Write-CkStep {
    param([string]$Message)
    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Assert-CkChildPath {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Parent
    )

    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $fullParent = [IO.Path]::GetFullPath($Parent).TrimEnd('\')
    if (-not $fullPath.StartsWith($fullParent + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "拒绝操作输出目录之外的路径: $fullPath"
    }
}

function Remove-CkBuildArtifact {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return }
    Assert-CkChildPath -Path $Path -Parent $OutputDirectory
    Remove-Item -LiteralPath $Path -Recurse -Force
}

function Copy-CkTree {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [string[]]$ExcludeDirectories = @(),
        [string[]]$ExcludeFiles = @()
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        throw "源目录不存在: $Source"
    }

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    $arguments = @(
        $Source,
        $Destination,
        '/E',
        '/COPY:DAT',
        '/DCOPY:DAT',
        '/R:1',
        '/W:1',
        '/NFL',
        '/NDL',
        '/NJH',
        '/NJS',
        '/NP'
    )
    if ($ExcludeDirectories.Count) {
        $arguments += '/XD'
        $arguments += $ExcludeDirectories
    }
    if ($ExcludeFiles.Count) {
        $arguments += '/XF'
        $arguments += $ExcludeFiles
    }

    & robocopy.exe @arguments
    $result = $LASTEXITCODE
    if ($result -ge 8) {
        throw "目录复制失败，robocopy 退出码: $result，源目录: $Source"
    }
}

function Copy-CkRequiredFile {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        throw "缺少打包文件: $Source"
    }

    $parent = Split-Path -Parent $Destination
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

if (-not (Test-Path -LiteralPath $ExeBuildScript -PathType Leaf)) {
    throw "找不到 EXE 构建脚本: $ExeBuildScript"
}

Write-CkStep '重新构建 CK免费工具箱.exe'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ExeBuildScript
if ($LASTEXITCODE -ne 0) {
    throw "EXE 构建失败，退出码: $LASTEXITCODE"
}

$sourceExe = Join-Path $ToolboxRoot 'CK免费工具箱.exe'
$rawVersion = (Get-Item -LiteralPath $sourceExe).VersionInfo.FileVersion
$versionParts = @($rawVersion -split '\.')
$releaseVersion = if ($versionParts.Count -ge 3) { ($versionParts[0..2] -join '.') } else { $rawVersion }
$packageName = "CK免费工具箱-v$releaseVersion"
$packagePath = Join-Path $OutputDirectory $packageName
$archivePath = Join-Path $OutputDirectory "$packageName.zip"

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
Remove-CkBuildArtifact -Path $packagePath
Remove-CkBuildArtifact -Path $archivePath
New-Item -ItemType Directory -Path $packagePath | Out-Null

Write-CkStep '复制工具箱客户端文件'
foreach ($fileName in @('CK免费工具箱.exe', 'CKFreeToolbox.ps1')) {
    Copy-CkRequiredFile -Source (Join-Path $ToolboxRoot $fileName) -Destination (Join-Path $packagePath $fileName)
}
foreach ($directoryName in @('app', 'static')) {
    Copy-CkTree -Source (Join-Path $ToolboxRoot $directoryName) -Destination (Join-Path $packagePath $directoryName) -ExcludeDirectories @('__pycache__', '.git') -ExcludeFiles @('*.pyc')
}

Write-CkStep '生成使用说明和发布清单'
$inputDirectory = Join-Path $packagePath 'TestVeh'
New-Item -ItemType Directory -Path $inputDirectory -Force | Out-Null
$inputGuide = @(
    '把需要截图的 FiveM 模型、资源目录或压缩包放到这里，也可以在工具箱中选择任意其他目录。',
    '支持 .yft、.ydr、.ydd、.ymap、.zip、.rar、.7z 和 .rpf。',
    '渲染结果默认输出到本目录下的 _vehicle_renders。'
) -join [Environment]::NewLine
[IO.File]::WriteAllText((Join-Path $inputDirectory '模型放这里.txt'), $inputGuide, $Utf8Bom)

$userGuide = @(
    'CK免费工具箱',
    '',
    '1. 解压完整 ZIP，不能只复制 EXE。',
    '2. 双击 CK免费工具箱.exe。',
    '3. 页面显示“组件缺失”时，点击“安装组件”，工具箱会下载当前页面对应的最新稳定 GitHub Release 并校验。',
    '4. 如果 Blender 显示未安装或版本过低，先安装 Blender 4.2+（推荐 5.1），再点击选择并指定 blender.exe。',
    '5. NUI/RPF 页面缺少 Python 时，点击“官网”自行安装 Python 3.7+，再点击“选择”指定 python.exe。',
    '6. Blender 与 Python 路径统一保存在工具箱根目录 config.json，自更新不会删除。',
    '7. 选择模型所在目录，点击“扫描模型”。',
    '8. 勾选需要处理的模型，点击“开始渲染”。',
    '9. 点击“打开输出”查看 PNG。',
    '',
    'NUI 自动去墙：',
    '1. 打开“NUI 自动去墙”，选择单个 FiveM resource 或 resources 目录。',
    '2. 先执行“安全扫描”或“预览方案”；这两步不会修改文件。',
    '3. 确认报告后执行“正式写入”，工具会在目标目录外创建备份。',
    '4. 需要撤销时，使用报告中的 Run ID 执行恢复。',
    '',
    'RPF 转 FiveM：',
    '1. 打开 RPF 转 FiveM 页面，选择输入目录、单个 RPF 或压缩包。',
    '2. 选择输出目录，按需调整覆盖、临时目录与安全限制。',
    '3. 点击开始转换，每个 RPF 会生成一个独立 FiveM resource。',
    '4. 转换后可直接打开输出目录，并查看资源明细和 JSON 报告。',
    '',
    'GitHub 组件管理：',
    '1. 工具箱启动后会在后台依次检查所有组件更新，不阻塞页面。',
    '2. 每个工具页面右上角可打开对应 GitHub 开源仓库。',
    '3. 组件缺失时点击“安装组件”，工具箱只下载已登记仓库的最新稳定 Release ZIP 并校验。',
    '4. 检查结果会显示最新版本或更新提示，发现更新后点击“更新组件”。',
    '5. 更新前自动备份旧组件；下载、解压或校验失败时不会覆盖当前组件。',
    '',
    '工具箱自动更新：',
    '1. 工具箱启动后会异步检查自身最新稳定 Release。',
    '2. 发现新版后点击顶部“立即更新”，工具箱会下载、校验、退出替换并自动重启。',
    '3. 自更新只替换工具箱核心文件，不删除 config.json、已安装组件、TestVeh、模型或渲染输出。',
    '',
    '发布包不包含 Blender 或 Python。Blender 需要 4.2+（推荐 5.1），Python 需要 3.7+。',
    'Python 缺失时 NUI/RPF 页面会打开 Python 官网，安装后可选择安装目录中的 python.exe。',
    '轻量发布包不预装功能组件；模型 Release 已内置 Sollumz；首次安装时会配置 Blender Python 渲染依赖。',
    '请勿删除 app 和 static 目录。运行后安装的 vehicle_renderer、nui-wallfix、rpf_to_fivem 目录也需要保留。',
    '支持 Windows 10/11 64 位系统。'
) -join [Environment]::NewLine
[IO.File]::WriteAllText((Join-Path $packagePath '使用说明.txt'), $userGuide, $Utf8Bom)

$requiredPackageFiles = @(
    (Join-Path $packagePath 'CK免费工具箱.exe'),
    (Join-Path $packagePath 'CKFreeToolbox.ps1'),
    (Join-Path $packagePath 'app\modules\ToolboxConfig.psm1'),
    (Join-Path $packagePath 'app\config\tools.json'),
    (Join-Path $packagePath 'app\workers\ComponentWorker.ps1'),
    (Join-Path $packagePath 'app\workers\SelfUpdateWorker.ps1'),
    (Join-Path $packagePath 'app\workers\ApplyToolboxUpdate.ps1'),
    (Join-Path $packagePath 'app\pages\ModelRenderPage.ps1'),
    (Join-Path $packagePath 'app\pages\NuiWallfixPage.ps1'),
    (Join-Path $packagePath 'app\pages\RpfToFivemPage.ps1'),
    (Join-Path $packagePath 'static\cklogo.ico')
)
foreach ($path in $requiredPackageFiles) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "发布包校验失败，缺少文件: $path"
    }
}
if (Test-Path -LiteralPath (Join-Path $packagePath 'runtime\blender')) {
    throw '发布包不应包含 Blender 运行时。'
}
if (Test-Path -LiteralPath (Join-Path $packagePath 'config.json') -PathType Leaf) {
    throw '发布包不应包含用户 config.json。'
}
if (@(Get-ChildItem -LiteralPath $packagePath -Recurse -File -Filter 'python.exe').Count -gt 0) {
    throw '发布包不应包含 Python 运行时。'
}

$manifest = [ordered]@{
    product = 'CK免费工具箱'
    version = $releaseVersion
    builtAt = (Get-Date).ToString('o')
    platform = 'Windows x64'
    entry = 'CK免费工具箱.exe'
    requirements = [ordered]@{
        blender = '4.2 or later, installed separately'
        python = 'Validated Python 3.7+ selected by the user, system Python, py.exe, or Blender Python'
        dotNetFramework = '4.8'
    }
    bundled = [ordered]@{
        blender = $false
        renderer = $false
        sollumz = $false
        codewalkerTools = $false
        sevenZip = $false
        nuiWallfix = $false
        rpfToFivem = $false
        componentManager = $true
        selfUpdater = $true
    }
    sha256 = [ordered]@{
        executable = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packagePath 'CK免费工具箱.exe')).Hash
        mainScript = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packagePath 'CKFreeToolbox.ps1')).Hash
        toolboxConfig = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packagePath 'app\modules\ToolboxConfig.psm1')).Hash
        componentWorker = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packagePath 'app\workers\ComponentWorker.ps1')).Hash
        selfUpdateWorker = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packagePath 'app\workers\SelfUpdateWorker.ps1')).Hash
        applyUpdateWorker = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packagePath 'app\workers\ApplyToolboxUpdate.ps1')).Hash
    }
}
[IO.File]::WriteAllText((Join-Path $packagePath 'package-manifest.json'), ($manifest | ConvertTo-Json -Depth 6), $Utf8NoBom)

$packageFiles = Get-ChildItem -LiteralPath $packagePath -Recurse -File
$packageBytes = ($packageFiles | Measure-Object Length -Sum).Sum
Write-Host ("发布目录: {0}" -f $packagePath) -ForegroundColor Green
Write-Host ("文件数量: {0}" -f $packageFiles.Count)
Write-Host ("未压缩大小: {0:N2} MB" -f ($packageBytes / 1MB))

if (-not $SkipArchive) {
    Write-CkStep '生成 ZIP 发布包'
    Compress-Archive -LiteralPath $packagePath -DestinationPath $archivePath -CompressionLevel Optimal -Force

    $archive = Get-Item -LiteralPath $archivePath
    Write-Host ("ZIP: {0}" -f $archive.FullName) -ForegroundColor Green
    Write-Host ("ZIP 大小: {0:N2} MB" -f ($archive.Length / 1MB))
}

if ($OpenOutput) {
    Start-Process -FilePath explorer.exe -ArgumentList @($OutputDirectory)
}
