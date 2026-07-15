[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('status', 'check', 'install')][string]$Action,
    [Parameter(Mandatory)][string]$ToolId,
    [Parameter(Mandatory)][string]$ConfigPath,
    [Parameter(Mandatory)][string]$UserConfigPath,
    [Parameter(Mandatory)][string]$WorkspaceRoot
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-CkProgress {
    param([int]$Percent, [string]$Message)

    $payload = [ordered]@{
        percent = [Math]::Max(0, [Math]::Min(100, $Percent))
        message = $Message
    } | ConvertTo-Json -Compress
    [Console]::Out.WriteLine("CK_PROGRESS $payload")
}

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

function Get-CkLocalVersion {
    param($Paths)

    if (Test-Path -LiteralPath $Paths.Manifest -PathType Leaf) {
        try {
            $manifest = Get-Content -LiteralPath $Paths.Manifest -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($manifest.releaseTag) { return [string]$manifest.releaseTag }
        } catch { }
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
        localVersion = Get-CkLocalVersion -Paths $Paths
        target = $Paths.Target
    }
}

function Get-CkRemoteRelease {
    param($Tool)

    $repo = [string]$Tool.component.repo
    $assetPattern = [string]$Tool.component.releaseAssetPattern
    if ($repo -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw "GitHub 仓库格式无效: $repo"
    }
    if ([string]::IsNullOrWhiteSpace($assetPattern) -or $assetPattern.Contains('/') -or -not $assetPattern.EndsWith('.zip', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Release 附件规则无效: $assetPattern"
    }
    if (@($assetPattern.ToCharArray() | Where-Object { $_ -eq '*' }).Count -gt 1) {
        throw "Release 附件规则最多允许一个版本通配符: $assetPattern"
    }

    Add-Type -AssemblyName System.Net.Http
    $client = New-Object Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromSeconds(30)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('CKFreeToolbox/1.0.2')
    $response = $null
    try {
        $latestUrl = "https://github.com/$repo/releases/latest"
        $response = $client.GetAsync($latestUrl, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
        if (-not $response.IsSuccessStatusCode) {
            throw "GitHub 仓库尚未发布稳定 Release: $repo"
        }
        $releaseUri = $response.RequestMessage.RequestUri
        if ($releaseUri.Scheme -ne 'https' -or $releaseUri.Host -ne 'github.com') {
            throw "GitHub Release 跳转地址无效: $releaseUri"
        }
        $segments = @($releaseUri.AbsolutePath.Trim('/').Split('/'))
        if ($segments.Count -ne 5 -or
            $segments[0] -ine ($repo -split '/')[0] -or
            $segments[1] -ine ($repo -split '/')[1] -or
            $segments[2] -ine 'releases' -or
            $segments[3] -ine 'tag') {
            throw "GitHub 最新 Release 跳转结构无效: $releaseUri"
        }
        $tag = [Uri]::UnescapeDataString($segments[4])
        if ($tag -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
            throw "GitHub Release 标签无效: $tag"
        }

        $assetName = if ($assetPattern.Contains('*')) { $assetPattern.Replace('*', $tag) } else { $assetPattern }
        if ($assetName -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,200}\.zip$') {
            throw "Release ZIP 附件名无效: $assetName"
        }
        $escapedTag = [Uri]::EscapeDataString($tag)
        $escapedAssetName = [Uri]::EscapeDataString($assetName)
        $assetUrl = "https://github.com/$repo/releases/download/$escapedTag/$escapedAssetName"

        $assetRequest = New-Object Net.Http.HttpRequestMessage([Net.Http.HttpMethod]::Head, $assetUrl)
        $assetResponse = $client.SendAsync($assetRequest, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
        try {
            if (-not $assetResponse.IsSuccessStatusCode) {
                throw "GitHub Release 缺少附件: $assetName"
            }
        } finally {
            $assetResponse.Dispose()
            $assetRequest.Dispose()
        }

        $checksumUrl = ''
        if ($Tool.component.PSObject.Properties['releaseChecksumAssetPattern']) {
            $checksumPattern = [string]$Tool.component.releaseChecksumAssetPattern
            if ([string]::IsNullOrWhiteSpace($checksumPattern) -or $checksumPattern.Contains('/') -or
                @($checksumPattern.ToCharArray() | Where-Object { $_ -eq '*' }).Count -gt 1) {
                throw "Release 校验附件规则无效: $checksumPattern"
            }
            $checksumName = if ($checksumPattern.Contains('*')) { $checksumPattern.Replace('*', $tag) } else { $checksumPattern }
            if ($checksumName -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,220}\.sha256$') {
                throw "Release 校验附件名无效: $checksumName"
            }
            $checksumUrl = "https://github.com/$repo/releases/download/$escapedTag/$([Uri]::EscapeDataString($checksumName))"
            $checksumRequest = New-Object Net.Http.HttpRequestMessage([Net.Http.HttpMethod]::Head, $checksumUrl)
            $checksumResponse = $client.SendAsync($checksumRequest, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
            try {
                if (-not $checksumResponse.IsSuccessStatusCode) {
                    throw "GitHub Release 缺少校验附件: $checksumName"
                }
            } finally {
                $checksumResponse.Dispose()
                $checksumRequest.Dispose()
            }
        }

        return [pscustomobject]@{
            Tag = $tag
            AssetName = $assetName
            AssetUrl = $assetUrl
            AssetDigest = ''
            ChecksumUrl = $checksumUrl
            HtmlUrl = $releaseUri.AbsoluteUri
        }
    } finally {
        if ($response) { $response.Dispose() }
        $client.Dispose()
    }
}

function Save-CkDownload {
    param(
        [string]$Url,
        [string]$Destination,
        [long]$MaxBytes = 536870912,
        [int]$StartPercent = 28,
        [int]$EndPercent = 58,
        [string]$Label = '正在下载组件'
    )

    $uri = [Uri]$Url
    if ($uri.Scheme -ne 'https' -or $uri.Host -notin @('github.com')) {
        throw "拒绝非 GitHub 下载地址: $Url"
    }
    Add-Type -AssemblyName System.Net.Http
    $client = New-Object Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromMinutes(10)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('CKFreeToolbox/1.0.2')
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
        $lastPercent = -1
        Write-CkProgress -Percent $StartPercent -Message $Label
        while (($read = $input.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $total += $read
            if ($total -gt $MaxBytes) { throw "组件下载超过大小限制: $MaxBytes bytes" }
            $output.Write($buffer, 0, $read)
            if ($length -and $length -gt 0) {
                $percent = $StartPercent + [int](($total / $length) * ($EndPercent - $StartPercent))
                $percent = [Math]::Min($EndPercent, $percent)
                if ($percent -gt $lastPercent) {
                    Write-CkProgress -Percent $percent -Message ("$Label {0:N1}/{1:N1} MB" -f ($total / 1MB), ($length / 1MB))
                    $lastPercent = $percent
                }
            }
        }
        Write-CkProgress -Percent $EndPercent -Message "$Label 完成"
    } finally {
        if ($output) { $output.Dispose() }
        if ($input) { $input.Dispose() }
        if ($response) { $response.Dispose() }
        $client.Dispose()
    }
}
function Assert-CkReleaseArchiveHash {
    param($Release, [string]$ArchivePath, [string]$StageRoot)

    $expectedHashes = New-Object System.Collections.Generic.List[string]
    if ($Release.AssetDigest) {
        $expectedHashes.Add(([string]$Release.AssetDigest).Substring(7).ToLowerInvariant())
    }
    if ($Release.ChecksumUrl) {
        $checksumPath = Join-Path $StageRoot 'component.zip.sha256'
        Save-CkDownload -Url ([string]$Release.ChecksumUrl) -Destination $checksumPath -MaxBytes 1048576 -StartPercent 59 -EndPercent 60 -Label '正在下载校验文件'
        $checksumText = [IO.File]::ReadAllText($checksumPath)
        $match = [regex]::Match($checksumText, '(?i)(?<![0-9a-f])[0-9a-f]{64}(?![0-9a-f])')
        if (-not $match.Success) {
            throw 'Release 校验附件没有有效的 SHA-256。'
        }
        $expectedHashes.Add($match.Value.ToLowerInvariant())
    }

    $actual = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $uniqueExpected = @($expectedHashes | Select-Object -Unique)
    if ($uniqueExpected.Count -gt 1) {
        throw 'GitHub digest 与 Release 校验附件不一致。'
    }
    if ($uniqueExpected.Count -eq 1 -and $actual -ne $uniqueExpected[0]) {
        throw "Release ZIP 的 SHA-256 校验失败。期望: $($uniqueExpected[0])，实际: $actual"
    }
    return $actual
}

function Expand-CkSafeZip {
    param([string]$ArchivePath, [string]$Destination)

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    $separator = [IO.Path]::DirectorySeparatorChar
    $destinationRoot = [IO.Path]::GetFullPath($Destination).TrimEnd($separator) + $separator
    $archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    [long]$expandedBytes = 0
    [long]$totalBytes = ($archive.Entries | Measure-Object -Property Length -Sum).Sum
    $lastPercent = 64
    Write-CkProgress -Percent 64 -Message '正在解压组件'
    try {
        foreach ($entry in $archive.Entries) {
            $expandedBytes += $entry.Length
            if ($expandedBytes -gt 1073741824) { throw '组件解压后超过 1 GB 限制。' }
            $relative = $entry.FullName.Replace([char]'/', $separator)
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
            if ($totalBytes -gt 0) {
                $percent = 64 + [int](($expandedBytes / $totalBytes) * 14)
                if ($percent -gt $lastPercent) {
                    Write-CkProgress -Percent ([Math]::Min(78, $percent)) -Message '正在解压组件'
                    $lastPercent = $percent
                }
            }
        }
    } finally {
        $archive.Dispose()
    }
    Write-CkProgress -Percent 78 -Message '组件解压完成'
}
function Get-CkBlenderPython {
    $blenderCandidates = New-Object System.Collections.Generic.List[string]
    if (Test-Path -LiteralPath $UserConfigPath -PathType Leaf) {
        try {
            $settings = Get-Content -LiteralPath $UserConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $selected = if ($settings.PSObject.Properties['dependencies'] -and $settings.dependencies.PSObject.Properties['blenderPath']) {
                [string]$settings.dependencies.blenderPath
            } elseif ($settings.PSObject.Properties['BlenderPath']) {
                [string]$settings.BlenderPath
            } else {
                ''
            }
            if (Test-Path -LiteralPath $selected -PathType Leaf) {
                $blenderCandidates.Add($selected)
            } elseif (Test-Path -LiteralPath $selected -PathType Container) {
                $directExe = Join-Path $selected 'blender.exe'
                if (Test-Path -LiteralPath $directExe -PathType Leaf) {
                    $blenderCandidates.Add($directExe)
                } else {
                    foreach ($directory in @(Get-ChildItem -LiteralPath $selected -Directory -ErrorAction SilentlyContinue)) {
                        $nestedExe = Join-Path $directory.FullName 'blender.exe'
                        if (Test-Path -LiteralPath $nestedExe -PathType Leaf) {
                            $blenderCandidates.Add($nestedExe)
                            break
                        }
                    }
                }
            }
        } catch { }
    }
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

function Initialize-CkVehicleRendererDependencies {
    param([string]$SourceRoot)

    $sollumzRoot = Join-Path $SourceRoot 'Sollumz'
    if (-not (Test-Path -LiteralPath (Join-Path $sollumzRoot '__init__.py') -PathType Leaf)) {
        throw '模型 Release 未包含有效的 Sollumz。'
    }

    Write-CkProgress -Percent 80 -Message '正在配置 Blender 运行依赖'
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
    & $runtime.Python -m pip install --disable-pip-version-check --no-input --target $sitePackages --no-deps --require-hashes -r $requirementsPath | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Sollumz Python 依赖安装失败，退出码: $LASTEXITCODE" }
    Write-CkProgress -Percent 89 -Message 'Blender 运行依赖配置完成'
}

function Install-CkComponent {
    param($Tool, $Paths, $Release)

    $repo = [string]$Tool.component.repo
    $stageBase = Join-Path ([IO.Path]::GetTempPath()) 'CKFreeToolbox'
    $stageName = ([string]$ToolId).Replace('-', '') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
    $stage = Assert-CkChildPath -Path (Join-Path $stageBase $stageName) -Parent $stageBase
    $archivePath = Join-Path $stage 'component.zip'
    $extractPath = Join-Path $stage 'extract'
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    try {
        Save-CkDownload -Url ([string]$Release.AssetUrl) -Destination $archivePath -StartPercent 28 -EndPercent 58 -Label '正在下载组件'
        Write-CkProgress -Percent 59 -Message '正在校验组件完整性'
        $archiveHash = Assert-CkReleaseArchiveHash -Release $Release -ArchivePath $archivePath -StageRoot $stage
        Write-CkProgress -Percent 63 -Message '组件校验通过'
        Expand-CkSafeZip -ArchivePath $archivePath -Destination $extractPath

        $sourceDirectories = @(Get-ChildItem -LiteralPath $extractPath -Directory)
        if ($sourceDirectories.Count -ne 1) {
            throw "Release ZIP 顶层目录数量不是 1: $($sourceDirectories.Count)"
        }
        $sourceRoot = $sourceDirectories[0].FullName
        $shortSourceRoot = Join-Path $stage 'src'
        Move-Item -LiteralPath $sourceRoot -Destination $shortSourceRoot
        $sourceRoot = $shortSourceRoot

        if ([string]$Tool.component.bootstrap -eq 'vehicle-renderer') {
            Initialize-CkVehicleRendererDependencies -SourceRoot $sourceRoot
        }
        foreach ($relative in @($Tool.component.requiredFiles)) {
            $required = Assert-CkChildPath -Path (Join-Path $sourceRoot ([string]$relative)) -Parent $sourceRoot
            if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
                throw "Release 组件缺少必需文件: $relative"
            }
        }

        Write-CkProgress -Percent 92 -Message '正在切换到新版本'
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
                schemaVersion = 2
                toolId = $ToolId
                repo = $repo
                releaseTag = [string]$Release.Tag
                assetName = [string]$Release.AssetName
                sha256 = $archiveHash
                source = 'github-release'
                installedAt = (Get-Date).ToString('o')
            }
            [IO.File]::WriteAllText($Paths.Manifest, ($manifest | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
        } catch {
            if (Test-Path -LiteralPath $Paths.Target) { Remove-CkDirectory -Path $Paths.Target }
            if ($movedOld -and (Test-Path -LiteralPath $backup)) { Move-Item -LiteralPath $backup -Destination $Paths.Target }
            throw
        }
        return [pscustomobject]@{
            Backup = $(if ($movedOld) { $backup } else { '' })
            Sha256 = $archiveHash
        }
    } finally {
        if (Test-Path -LiteralPath $stage) { Remove-CkDirectory -Path $stage }
    }
}

try {
    Write-CkProgress -Percent 3 -Message '正在读取组件状态'
    $tool = Get-CkToolConfig
    $paths = Get-CkComponentPaths -Tool $tool
    $local = Get-CkLocalStatus -Tool $tool -Paths $paths
    $result = [ordered]@{
        schemaVersion = 2
        action = $Action
        toolId = $ToolId
        title = [string]$tool.title
        repo = [string]$tool.component.repo
        installed = [bool]$local.installed
        missingFiles = @($local.missingFiles)
        localVersion = [string]$local.localVersion
        latestVersion = ''
        releaseAsset = ''
        releaseUrl = ''
        sha256 = ''
        updateAvailable = $false
        target = [string]$local.target
        backup = ''
        status = if ($local.installed) { 'installed' } else { 'missing' }
    }

    $remoteRelease = $null
    if ($Action -in @('check', 'install')) {
        Write-CkProgress -Percent 8 -Message '正在连接 GitHub Release'
        $remoteRelease = Get-CkRemoteRelease -Tool $tool
        Write-CkProgress -Percent $(if ($Action -eq 'check') { 88 } else { 25 }) -Message "已找到 $($remoteRelease.Tag)"
        $result.latestVersion = [string]$remoteRelease.Tag
        $result.releaseAsset = [string]$remoteRelease.AssetName
        $result.releaseUrl = [string]$remoteRelease.HtmlUrl
        $result.updateAvailable = (-not $local.installed) -or (-not $local.localVersion) -or ($local.localVersion -ne $result.latestVersion)
    }
    if ($Action -eq 'install') {
        $installResult = Install-CkComponent -Tool $tool -Paths $paths -Release $remoteRelease
        $result.backup = [string]$installResult.Backup
        $result.sha256 = [string]$installResult.Sha256
        $local = Get-CkLocalStatus -Tool $tool -Paths $paths
        $result.installed = [bool]$local.installed
        $result.missingFiles = @($local.missingFiles)
        $result.localVersion = [string]$local.localVersion
        $result.updateAvailable = $false
        $result.status = 'installed'
    } elseif ($Action -eq 'check' -and $result.updateAvailable) {
        $result.status = 'update-available'
    }
    Write-CkProgress -Percent 100 -Message $(if ($Action -eq 'install') { '组件安装完成' } else { '更新检查完成' })
    $result | ConvertTo-Json -Depth 6 -Compress
    exit 0
} catch {
    [ordered]@{
        schemaVersion = 2
        action = $Action
        toolId = $ToolId
        status = 'error'
        error = $_.Exception.Message
    } | ConvertTo-Json -Depth 4 -Compress
    exit 1
}
