[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('status', 'check', 'install')][string]$Action,
    [Parameter(Mandatory)][string]$ToolId,
    [Parameter(Mandatory)][string]$ConfigPath,
    [Parameter(Mandatory)][string]$WorkspaceRoot
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Assert-CkChildPath {
    param([string]$Path, [string]$Parent)

    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $fullParent = [IO.Path]::GetFullPath($Parent).TrimEnd('\')
    if (-not $fullPath.StartsWith($fullParent + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "组件路径越界: $fullPath"
    }
    return $fullPath
}

function Remove-CkDirectory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return }
    $fullPath = [IO.Path]::GetFullPath($Path)
    $longPath = if ($fullPath.StartsWith('\\?\')) { $fullPath } else { '\\?\' + $fullPath }
    [IO.Directory]::Delete($longPath, $true)
    if (Test-Path -LiteralPath $Path) {
        throw "无法清理组件目录: $Path"
    }
}

function Get-CkToolConfig {
    $tools = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $tool = @($tools | Where-Object { [string]$_.id -eq $ToolId })[0]
    if (-not $tool) { throw "工具配置不存在: $ToolId" }
    if (-not $tool.PSObject.Properties['component']) { throw "工具未配置组件: $ToolId" }
    return $tool
}

function Get-CkComponentPaths {
    param($Tool)

    $workspace = [IO.Path]::GetFullPath($WorkspaceRoot).TrimEnd('\')
    if (-not (Test-Path -LiteralPath $workspace -PathType Container)) {
        throw "工具箱工作区不存在: $workspace"
    }
    $target = Assert-CkChildPath -Path (Join-Path $workspace ([string]$Tool.component.installDir)) -Parent $workspace
    return [pscustomobject]@{
        Workspace = $workspace
        Target = $target
        Manifest = Join-Path $target '.ck-component.json'
    }
}

function Get-CkLocalCommit {
    param($Paths)

    if (Test-Path -LiteralPath $Paths.Manifest -PathType Leaf) {
        try {
            $manifest = Get-Content -LiteralPath $Paths.Manifest -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($manifest.commit) { return [string]$manifest.commit }
        } catch { }
    }
    if (Test-Path -LiteralPath (Join-Path $Paths.Target '.git')) {
        $git = Get-Command git.exe -ErrorAction SilentlyContinue
        if ($git) {
            $commit = (& $git.Source -C $Paths.Target rev-parse HEAD 2>$null | Select-Object -First 1)
            if ($LASTEXITCODE -eq 0 -and $commit) { return [string]$commit }
        }
    }
    return ''
}

function Get-CkLocalStatus {
    param($Tool, $Paths)

    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($relative in @($Tool.component.requiredFiles)) {
        $required = Assert-CkChildPath -Path (Join-Path $Paths.Target ([string]$relative)) -Parent $Paths.Target
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
            $missing.Add([string]$relative)
        }
    }
    return [ordered]@{
        installed = ($missing.Count -eq 0)
        missingFiles = @($missing)
        localCommit = Get-CkLocalCommit -Paths $Paths
        target = $Paths.Target
    }
}

function Get-CkRemoteCommit {
    param($Tool)

    $repo = [string]$Tool.component.repo
    $branch = [string]$Tool.component.branch
    if ($repo -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') { throw "GitHub 仓库格式无效: $repo" }
    if ($branch -notmatch '^[A-Za-z0-9._/-]+$') { throw "GitHub 分支格式无效: $branch" }
    $headers = @{
        'User-Agent' = 'CKFreeToolbox/1.0.1'
        'Accept' = 'application/vnd.github+json'
    }
    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/commits/$branch" -Headers $headers -TimeoutSec 20
    $commit = [string]$response.sha
    if ($commit -notmatch '^[0-9a-f]{40}$') { throw 'GitHub 未返回有效提交版本。' }
    return $commit
}

function Save-CkDownload {
    param([string]$Url, [string]$Destination, [long]$MaxBytes = 536870912)

    $uri = [Uri]$Url
    if ($uri.Scheme -ne 'https' -or $uri.Host -notin @('github.com', 'codeload.github.com')) {
        throw "拒绝非 GitHub 下载地址: $Url"
    }
    Add-Type -AssemblyName System.Net.Http
    $client = New-Object Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromMinutes(10)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('CKFreeToolbox/1.0.1')
    $response = $null
    $input = $null
    $output = $null
    try {
        $response = $client.GetAsync($uri, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
        $response.EnsureSuccessStatusCode() | Out-Null
        $length = $response.Content.Headers.ContentLength
        if ($length -and $length -gt $MaxBytes) { throw "组件下载超过大小限制: $length bytes" }
        $input = $response.Content.ReadAsStreamAsync().Result
        $output = [IO.File]::Open($Destination, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $buffer = New-Object byte[] 1048576
        [long]$total = 0
        while (($read = $input.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $total += $read
            if ($total -gt $MaxBytes) { throw "组件下载超过大小限制: $MaxBytes bytes" }
            $output.Write($buffer, 0, $read)
        }
    } finally {
        if ($output) { $output.Dispose() }
        if ($input) { $input.Dispose() }
        if ($response) { $response.Dispose() }
        $client.Dispose()
    }
}

function Expand-CkSafeZip {
    param([string]$ArchivePath, [string]$Destination)

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    $destinationRoot = [IO.Path]::GetFullPath($Destination).TrimEnd('\') + '\'
    $archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    [long]$expandedBytes = 0
    try {
        foreach ($entry in $archive.Entries) {
            $expandedBytes += $entry.Length
            if ($expandedBytes -gt 1073741824) { throw '组件解压后超过 1 GB 限制。' }
            $relative = $entry.FullName.Replace('/', '\')
            if ([string]::IsNullOrWhiteSpace($relative)) { continue }
            $destinationPath = [IO.Path]::GetFullPath((Join-Path $Destination $relative))
            if (-not $destinationPath.StartsWith($destinationRoot, [StringComparison]::OrdinalIgnoreCase)) {
                throw "ZIP 包含越界路径: $relative"
            }
            if ([string]::IsNullOrEmpty($entry.Name)) {
                New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
                continue
            }
            $parent = Split-Path -Parent $destinationPath
            if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            $source = $entry.Open()
            $target = [IO.File]::Open($destinationPath, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try { $source.CopyTo($target) } finally { $target.Dispose(); $source.Dispose() }
        }
    } finally {
        $archive.Dispose()
    }
}

function Get-CkBlenderPython {
    $blenderCandidates = New-Object System.Collections.Generic.List[string]
    foreach ($name in @('BLENDER_EXE', 'BLENDER_PATH')) {
        $value = [Environment]::GetEnvironmentVariable($name)
        if ($value) { $blenderCandidates.Add($value) }
    }
    $command = Get-Command blender.exe -ErrorAction SilentlyContinue
    if ($command) { $blenderCandidates.Add($command.Source) }
    $programFiles = [Environment]::GetFolderPath('ProgramFiles')
    $blenderRoot = Join-Path $programFiles 'Blender Foundation'
    if (Test-Path -LiteralPath $blenderRoot -PathType Container) {
        foreach ($directory in @(Get-ChildItem -LiteralPath $blenderRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
            $blenderCandidates.Add((Join-Path $directory.FullName 'blender.exe'))
        }
    }
    foreach ($blenderExe in $blenderCandidates) {
        if (-not (Test-Path -LiteralPath $blenderExe -PathType Leaf)) { continue }
        $root = Split-Path -Parent $blenderExe
        foreach ($version in @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
            $python = Join-Path $version.FullName 'python\bin\python.exe'
            if (Test-Path -LiteralPath $python -PathType Leaf) {
                return [pscustomobject]@{ Blender = $blenderExe; Python = $python }
            }
        }
    }
    throw '模型截图组件安装需要 Blender 4.2 或更高版本。请先安装 Blender。'
}

function Install-CkVehicleRendererDependencies {
    param($Tool, [string]$SourceRoot, [string]$StageRoot)

    $releaseUrl = [string]$Tool.component.sollumzAssetUrl
    $sollumzArchive = Join-Path $StageRoot 'sollumz.zip'
    $sollumzExtract = Join-Path $StageRoot 'sollumz-extract'
    Save-CkDownload -Url $releaseUrl -Destination $sollumzArchive -MaxBytes 104857600
    Expand-CkSafeZip -ArchivePath $sollumzArchive -Destination $sollumzExtract
    $sollumzSource = Join-Path $sollumzExtract 'Sollumz'
    if (-not (Test-Path -LiteralPath (Join-Path $sollumzSource '__init__.py') -PathType Leaf)) {
        throw 'Sollumz Release 结构无效。'
    }
    Move-Item -LiteralPath $sollumzSource -Destination (Join-Path $SourceRoot 'Sollumz')

    $runtime = Get-CkBlenderPython
    $pythonVersion = (& $runtime.Python -c "import sys; print('%d.%d' % sys.version_info[:2])" | Select-Object -First 1).Trim()
    $pymateriaHashes = @{
        '3.10' = '830867304a8986d89cfe4dc49f26c8e014f2c2558dd4e208ba3247588cf6ba16'
        '3.11' = 'c204fafc411dfd85992565c8fe1c16af0ee4e7af47620e8403e25d5103103795'
        '3.12' = '24bfd244b95e2fa8a96af8bbaa5133708640e6008035ae3a32be285d52f4135'
        '3.13' = '232052dd8c6942fa8a96af8bbaa5133708640e6008035ae3a32be285d52f297d'
        '3.14' = '91d384a543521089b0f4abb214e64b1839ef6afbedfa6574ee90be826944dbad'
    }
    if (-not $pymateriaHashes.ContainsKey($pythonVersion)) {
        throw "Blender Python $pythonVersion 暂无 PyMateria 安装校验值。"
    }
    $configRoot = Join-Path $SourceRoot 'blender_user_config'
    $dataRoot = Join-Path $configRoot 'sollumz\data'
    $sitePackages = Join-Path $dataRoot "lib\python$pythonVersion\site-packages"
    New-Item -ItemType Directory -Path $sitePackages -Force | Out-Null
    $requirements = @(
        '--extra-index-url https://static.cfx.re/whl/'
        'szio==1.2.0 --hash=sha256:2ab48ca953027a850a1087fe06504bb13d97890159c38dc838f4fdb9b4df6ebc'
        "pymateria==0.1.1 --hash=sha256:$($pymateriaHashes[$pythonVersion])"
    ) -join [Environment]::NewLine
    $requirementsPath = Join-Path $dataRoot 'requirements.txt'
    New-Item -ItemType Directory -Path $dataRoot -Force | Out-Null
    [IO.File]::WriteAllText($requirementsPath, $requirements, (New-Object Text.UTF8Encoding($false)))
    & $runtime.Python -m pip install --disable-pip-version-check --no-input --target $sitePackages --no-deps --require-hashes -r $requirementsPath
    if ($LASTEXITCODE -ne 0) { throw "Sollumz Python 依赖安装失败，退出码: $LASTEXITCODE" }
}

function Install-CkComponent {
    param($Tool, $Paths, [string]$Commit)

    $repo = [string]$Tool.component.repo
    $stageBase = Join-Path ([IO.Path]::GetTempPath()) 'CKFreeToolbox'
    $stageName = ([string]$ToolId).Replace('-', '') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
    $stage = Assert-CkChildPath -Path (Join-Path $stageBase $stageName) -Parent $stageBase
    $archivePath = Join-Path $stage 'component.zip'
    $extractPath = Join-Path $stage 'extract'
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    try {
        Save-CkDownload -Url "https://codeload.github.com/$repo/zip/$Commit" -Destination $archivePath
        Expand-CkSafeZip -ArchivePath $archivePath -Destination $extractPath
        $sourceRoot = @(Get-ChildItem -LiteralPath $extractPath -Directory | Select-Object -First 1)[0].FullName
        if (-not $sourceRoot) { throw 'GitHub 组件 ZIP 没有项目目录。' }
        $shortSourceRoot = Join-Path $stage 'src'
        Move-Item -LiteralPath $sourceRoot -Destination $shortSourceRoot
        $sourceRoot = $shortSourceRoot
        if ([string]$Tool.component.bootstrap -eq 'vehicle-renderer') {
            Install-CkVehicleRendererDependencies -Tool $Tool -SourceRoot $sourceRoot -StageRoot $stage
        }
        foreach ($relative in @($Tool.component.requiredFiles)) {
            $required = Assert-CkChildPath -Path (Join-Path $sourceRoot ([string]$relative)) -Parent $sourceRoot
            if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
                throw "下载的组件缺少必需文件: $relative"
            }
        }
        $backupRoot = Join-Path $Paths.Workspace '.ck-component-backups'
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
        $backup = Assert-CkChildPath -Path (Join-Path $backupRoot ("$ToolId-" + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))) -Parent $backupRoot
        $movedOld = $false
        try {
            if (Test-Path -LiteralPath $Paths.Target) {
                Move-Item -LiteralPath $Paths.Target -Destination $backup
                $movedOld = $true
            }
            Move-Item -LiteralPath $sourceRoot -Destination $Paths.Target
            $manifest = [ordered]@{
                schemaVersion = 1
                toolId = $ToolId
                repo = $repo
                branch = [string]$Tool.component.branch
                commit = $Commit
                installedAt = (Get-Date).ToString('o')
            }
            [IO.File]::WriteAllText($Paths.Manifest, ($manifest | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
        } catch {
            if (Test-Path -LiteralPath $Paths.Target) { Remove-CkDirectory -Path $Paths.Target }
            if ($movedOld -and (Test-Path -LiteralPath $backup)) { Move-Item -LiteralPath $backup -Destination $Paths.Target }
            throw
        }
        return $(if ($movedOld) { $backup } else { '' })
    } finally {
        if (Test-Path -LiteralPath $stage) { Remove-CkDirectory -Path $stage }
    }
}

try {
    $tool = Get-CkToolConfig
    $paths = Get-CkComponentPaths -Tool $tool
    $local = Get-CkLocalStatus -Tool $tool -Paths $paths
    $result = [ordered]@{
        schemaVersion = 1
        action = $Action
        toolId = $ToolId
        title = [string]$tool.title
        repo = [string]$tool.component.repo
        installed = [bool]$local.installed
        missingFiles = @($local.missingFiles)
        localCommit = [string]$local.localCommit
        latestCommit = ''
        updateAvailable = $false
        target = [string]$local.target
        backup = ''
        status = if ($local.installed) { 'installed' } else { 'missing' }
    }
    if ($Action -in @('check', 'install')) {
        $result.latestCommit = Get-CkRemoteCommit -Tool $tool
        $result.updateAvailable = (-not $local.installed) -or (-not $local.localCommit) -or ($local.localCommit -ne $result.latestCommit)
    }
    if ($Action -eq 'install') {
        $result.backup = Install-CkComponent -Tool $tool -Paths $paths -Commit $result.latestCommit
        $local = Get-CkLocalStatus -Tool $tool -Paths $paths
        $result.installed = [bool]$local.installed
        $result.missingFiles = @($local.missingFiles)
        $result.localCommit = [string]$local.localCommit
        $result.updateAvailable = $false
        $result.status = 'installed'
    } elseif ($Action -eq 'check' -and $result.updateAvailable) {
        $result.status = 'update-available'
    }
    $result | ConvertTo-Json -Depth 6 -Compress
    exit 0
} catch {
    [ordered]@{
        schemaVersion = 1
        action = $Action
        toolId = $ToolId
        status = 'error'
        error = $_.Exception.Message
    } | ConvertTo-Json -Depth 4 -Compress
    exit 1
}
