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
    '3. 首次启动需阅读并同意使用及免责条款；同意状态只记录在工具箱根目录 config.json。',
    '4. “扫描移除后门”和“一键清理小哈”已内置；其他页面显示“组件缺失”时，可点击“安装组件”下载并校验最新稳定 GitHub Release。',
    '5. 如果 Blender 显示未安装或版本过低，先安装 Blender 4.2+（推荐 5.1），再点击选择并指定 blender.exe。',
    '6. NUI/RPF/扫描移除后门/一键清理小哈页面缺少 Python 时，点击“官网”自行安装 Python 3.7+，再点击“选择”指定 python.exe。',
    '7. Blender、Python 等依赖路径和条款同意状态统一保存在工具箱根目录 config.json，自更新不会删除。',
    '8. 选择模型所在目录，点击“扫描模型”。',
    '9. 勾选需要处理的模型，点击“开始渲染”。',
    '10. 点击“打开输出”查看 PNG。',
    '',
    'NUI 自动去墙：',
    '1. 打开“NUI 自动去墙”，选择单个 FiveM resource 或 resources 目录。',
    '2. 先执行“安全扫描”或“预览方案”；这两步不会修改文件。',
    '3. 确认报告后执行“正式写入”，工具会在目标目录外创建备份。',
    '4. 需要撤销时，使用报告中的 Run ID 执行恢复。',
    '',
    '服务器 Dump：',
    '1. 打开“服务器 Dump”，输入 cfx.re link 或 IP:端口。',
    '2. 工具默认使用 token_choice=1 自动扫描 FiveM 进程 token，请先进入目标服务器。',
    '3. 功能含服务器 Dump、解密 FXAP，不含修复模型。',
    '4. 任务结束后可打开输出目录，并查看本次 Markdown/JSON 报告。',
    '',
    'FXAP 文件夹解密：',
    '1. 选择直接包含 .fxap 的 resource，或包含多个 resource 的父目录。',
    '2. CFX server key 可留空；当前 resource 密钥不完整时由 fxap_only 查询 Keymaster grants API，客户端派生再调用 Cloudflare。',
    '3. 工具箱不提供、保存或传递 Bearer Token；接口鉴权只由 fxap_only 处理。',
    '4. Node.js 18+ 需要外部安装；Java 可选，也可以在页面选择外部 Java 目录。',
    '5. 输出自动写到相邻的 <目录名>_decrypted；未安装 Java 时 Lua 保留为 .luac。',
    '6. 任务结束后可打开本次 Markdown/JSON 报告，也可从“报告历史”查看以往记录。',
    '',
    'RPF 转 FiveM：',
    '1. 打开 RPF 转 FiveM 页面，选择输入目录、单个 RPF 或压缩包。',
    '2. 选择输出目录，按需调整覆盖、临时目录与安全限制。',
    '3. 点击开始转换，每个 RPF 会生成一个独立 FiveM resource。',
    '4. 转换后可直接打开输出目录，并查看资源明细和 JSON 报告。',
    '地图冲突合并：',
    '1. 选择包含 GTA5.exe 的 GTA V 安装目录。工具会读取原版 RPF 作为合并基线。',
    '2. 选择包含两个或更多地图 resources 的 Mods 目录，以及 snowy_merger 的输出父目录。',
    '3. 点击开始合并；页面会实时显示冲突数量、已处理文件组和完整日志。',
    '4. 结果写入 <输出>\snowy_merger，并保存一份本地任务日志。',
    '5. 在服务器中让 snowy_merger 晚于被替代的地图资源启动，并处理重复冲突文件。',
    '',
    '衣服资源打包：',
    '1. 页面只调用 Red40 Clothing Repacker 的 Windows x64 CLI，不启动上游 GUI。',
    '2. “分析打包方案”支持扫描资源父目录或逐个指定 resource，并可配置集合前缀、drawable 上限和 YMT 优化。',
    '3. 先校验并生成预览资源；确认 plan、报告和输出无误后，再执行 apply。',
    '4. apply 默认先复制资源到方案输出目录；关闭该选项会直接修改源 resource，执行前必须停服并保留完整备份。',
    '5. restore、三种 validate、report 和 export-xml 均可在同一中文页面使用，原始 CLI 输出会保存到本地任务日志。',
    '6. build/apply 只接受本页面 analyze 生成且方案/规划输入哈希未变化的方案；restore 只接受本页面 apply 记录且清单/独立备份哈希通过的恢复文件。',
    '',
    '一键清理小哈：',
    '1. 选择 FiveM server-data 或 resources 目录，先执行“只读扫描”。',
    '2. 确认资源、注入和 SQL 清单后再执行清理；文件会移动到目标外的隔离目录。',
    '3. 数据库清理默认关闭；启用前必须停止服务器、备份数据库并再次确认。',
    '4. 工具会自动读取 server.cfg 和 exec 配置链中的 MySQL 信息，密码不会输出到报告。',
    '5. 文件修改可选择 run-report.json 恢复；数据库只能从执行前的备份恢复。',
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
    '发布包不包含 Blender、Python、Node.js 或 Java。Blender 需要 4.2+（推荐 5.1），Python 需要 3.7+，FXAP 页面需要 Node.js 18+；Java 8+ 仅用于 Lua 反编译。',
    'Python 缺失时 NUI/RPF/扫描移除后门/一键清理小哈页面会打开 Python 官网，安装后可选择安装目录中的 python.exe。',
    '正式发布包内置“扫描移除后门”和“一键清理小哈”；模型、NUI、RPF、服务器 Dump 和 FXAP 组件按需安装。',
    'SnowyMerger 地图冲突合并组件同样按需安装，不会预装进工具箱发布包。',
    'Red40 衣服资源打包 CLI 同样按需安装，不会预装进工具箱发布包。',
    '请勿删除 app 和 static 目录。运行后安装的 vehicle_renderer、nui-wallfix、rpf_to_fivem、dump-tool、fxap-decryptor、ck_anti_john、xiaoha_cleaner 目录也需要保留。',
    '运行后安装的 snowy-merger 和 red40-clothing-packer 目录也需要保留。',
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
    (Join-Path $packagePath 'app\pages\ServerDumpPage.ps1'),
    (Join-Path $packagePath 'app\pages\FxapDecryptorPage.ps1'),
    (Join-Path $packagePath 'app\pages\SnowyMergerPage.ps1'),
    (Join-Path $packagePath 'app\pages\ClothingRepackerPage.ps1'),
    (Join-Path $packagePath 'app\pages\AntiJohnPage.ps1'),
    (Join-Path $packagePath 'app\pages\XiaohaCleanerPage.ps1'),
    (Join-Path $packagePath 'app\pages\EnhancedConverterPage.ps1'),
    (Join-Path $packagePath 'app\tools\alchemist\AlchemistCli.exe'),
    (Join-Path $packagePath 'app\tools\alchemist\AlchemistBatchWorker.ps1'),
    (Join-Path $packagePath 'app\tools\alchemist\alchemist-config.txt'),
    (Join-Path $packagePath 'app\tools\alchemist\LICENSES.txt'),
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
if (@(Get-ChildItem -LiteralPath $packagePath -Recurse -File -Filter 'node.exe').Count -gt 0) {
    throw '发布包不应包含 Node.js 运行时。'
}
if (@(Get-ChildItem -LiteralPath $packagePath -Recurse -File -Filter 'java.exe').Count -gt 0) {
    throw '发布包不应包含 Java 运行时。'
}

$manifest = [ordered]@{
    product = 'CK免费工具箱'
    version = $releaseVersion
    flavor = 'base-build-stage'
    builtAt = (Get-Date).ToString('o')
    platform = 'Windows x64'
    entry = 'CK免费工具箱.exe'
    requirements = [ordered]@{
        blender = '4.2 or later, installed separately'
        python = 'Validated Python 3.7+ selected by the user, system Python, py.exe, or Blender Python'
        node = 'Node.js 18 or later, installed separately'
        java = 'Optional Java 8 or later for Lua decompilation, installed separately'
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
        antiJohn = $false
        xiaohaCleaner = $false
        dumpTool = $false
        fxapDecryptor = $false
        snowyMerger = $false
        clothingRepacker = $false
        alchemist = $true
        componentManager = $true
        selfUpdater = $true
    }
    bundledComponents = [ordered]@{}
    sha256 = [ordered]@{
        executable = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packagePath 'CK免费工具箱.exe')).Hash
        mainScript = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packagePath 'CKFreeToolbox.ps1')).Hash
        toolboxConfig = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packagePath 'app\modules\ToolboxConfig.psm1')).Hash
        componentWorker = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packagePath 'app\workers\ComponentWorker.ps1')).Hash
        selfUpdateWorker = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packagePath 'app\workers\SelfUpdateWorker.ps1')).Hash
        applyUpdateWorker = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packagePath 'app\workers\ApplyToolboxUpdate.ps1')).Hash
        alchemistCli = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packagePath 'app\tools\alchemist\AlchemistCli.exe')).Hash
        alchemistWorker = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packagePath 'app\tools\alchemist\AlchemistBatchWorker.ps1')).Hash
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
