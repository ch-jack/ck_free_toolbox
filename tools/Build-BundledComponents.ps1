[CmdletBinding()]
param(
    [string]$OutputDirectory = '',
    [string]$BasePackagePath = '',
    [string[]]$ToolIds = @('anti-john', 'xiaoha-cleaner'),
    [switch]$SkipArchive
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ToolboxRoot = Split-Path -Parent $PSScriptRoot
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $ToolboxRoot 'dist'
}
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory).TrimEnd('\')

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
        throw "路径越界: $fullPath"
    }
    return $fullPath
}

function Remove-CkBuildArtifact {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return }
    $safePath = Assert-CkChildPath -Path $Path -Parent $OutputDirectory
    Remove-Item -LiteralPath $safePath -Recurse -Force
}

function Copy-CkTree {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        throw "复制源目录不存在: $Source"
    }
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    & robocopy.exe $Source $Destination /E /COPY:DAT /DCOPY:DAT /R:1 /W:1 /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -ge 8) {
        throw "目录复制失败，robocopy 退出码: $LASTEXITCODE"
    }
}

function New-CkHttpClient {
    Add-Type -AssemblyName System.Net.Http
    $handler = New-Object Net.Http.HttpClientHandler
    $handler.AllowAutoRedirect = $true
    $client = New-Object Net.Http.HttpClient($handler)
    $client.Timeout = [TimeSpan]::FromMinutes(10)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('CKFreeToolbox-BundledComponentsBuilder/1.0')
    return $client
}

function Assert-CkGitHubRepo {
    param([string]$Repository)
    if ($Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw "GitHub 仓库格式无效: $Repository"
    }
}

function Resolve-CkAssetName {
    param(
        [string]$Pattern,
        [string]$Tag,
        [string]$ExpectedSuffix
    )

    if (
        [string]::IsNullOrWhiteSpace($Pattern) -or
        $Pattern.Contains('/') -or
        @($Pattern.ToCharArray() | Where-Object { $_ -eq '*' }).Count -gt 1
    ) {
        throw "Release 附件规则无效: $Pattern"
    }
    $name = if ($Pattern.Contains('*')) { $Pattern.Replace('*', $Tag) } else { $Pattern }
    if (
        $name -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,220}$' -or
        -not $name.EndsWith($ExpectedSuffix, [StringComparison]::OrdinalIgnoreCase)
    ) {
        throw "Release 附件名无效: $name"
    }
    return $name
}

function Get-CkLatestStableRelease {
    param($Client, $Tool)

    $repo = [string]$Tool.component.repo
    Assert-CkGitHubRepo -Repository $repo
    $response = $null
    try {
        $response = $Client.GetAsync(
            "https://github.com/$repo/releases/latest",
            [Net.Http.HttpCompletionOption]::ResponseHeadersRead
        ).Result
        if (-not $response.IsSuccessStatusCode) {
            throw "GitHub 仓库没有可用的正式 Release: $repo"
        }
        $releaseUri = $response.RequestMessage.RequestUri
        if ($releaseUri.Scheme -ne 'https' -or $releaseUri.Host -ne 'github.com') {
            throw "GitHub Release 跳转地址无效: $releaseUri"
        }
        $segments = @($releaseUri.AbsolutePath.Trim('/').Split('/'))
        $repoParts = @($repo.Split('/'))
        if (
            $segments.Count -ne 5 -or
            $segments[0] -ine $repoParts[0] -or
            $segments[1] -ine $repoParts[1] -or
            $segments[2] -ine 'releases' -or
            $segments[3] -ine 'tag'
        ) {
            throw "GitHub 最新正式 Release 跳转结构无效: $releaseUri"
        }
        $tag = [Uri]::UnescapeDataString($segments[4])
        if ($tag -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
            throw "GitHub Release 标签无效: $tag"
        }
        if (-not $Tool.component.PSObject.Properties['releaseChecksumAssetPattern']) {
            throw "内置组件必须配置 SHA-256 附件: $($Tool.id)"
        }
        $assetName = Resolve-CkAssetName -Pattern ([string]$Tool.component.releaseAssetPattern) -Tag $tag -ExpectedSuffix '.zip'
        $checksumName = Resolve-CkAssetName -Pattern ([string]$Tool.component.releaseChecksumAssetPattern) -Tag $tag -ExpectedSuffix '.sha256'
        $escapedTag = [Uri]::EscapeDataString($tag)
        return [pscustomobject]@{
            Tag = $tag
            Repository = $repo
            HtmlUrl = $releaseUri.AbsoluteUri
            AssetName = $assetName
            AssetUrl = "https://github.com/$repo/releases/download/$escapedTag/$([Uri]::EscapeDataString($assetName))"
            ChecksumName = $checksumName
            ChecksumUrl = "https://github.com/$repo/releases/download/$escapedTag/$([Uri]::EscapeDataString($checksumName))"
        }
    } finally {
        if ($response) { $response.Dispose() }
    }
}

function Save-CkDownload {
    param(
        $Client,
        [string]$Url,
        [string]$Destination,
        [long]$MaxBytes
    )

    $uri = [Uri]$Url
    if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'github.com') {
        throw "拒绝非 GitHub 下载地址: $Url"
    }
    $response = $null
    $input = $null
    $output = $null
    try {
        $response = $Client.GetAsync(
            $uri,
            [Net.Http.HttpCompletionOption]::ResponseHeadersRead
        ).Result
        $response.EnsureSuccessStatusCode() | Out-Null
        $finalUri = $response.RequestMessage.RequestUri
        $finalHost = $finalUri.Host.ToLowerInvariant()
        if (
            $finalUri.Scheme -ne 'https' -or
            (
                $finalHost -ne 'github.com' -and
                -not $finalHost.EndsWith('.githubusercontent.com')
            )
        ) {
            throw "GitHub 附件跳转到了未允许的主机: $finalUri"
        }
        $length = $response.Content.Headers.ContentLength
        if ($length -and $length -gt $MaxBytes) {
            throw "下载附件超过大小限制: $length > $MaxBytes"
        }
        $parent = Split-Path -Parent $Destination
        if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        $input = $response.Content.ReadAsStreamAsync().Result
        $output = [IO.File]::Open(
            $Destination,
            [IO.FileMode]::Create,
            [IO.FileAccess]::Write,
            [IO.FileShare]::None
        )
        $buffer = New-Object byte[] 1048576
        [long]$total = 0
        while (($read = $input.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $total += $read
            if ($total -gt $MaxBytes) {
                throw "下载附件超过大小限制: $MaxBytes"
            }
            $output.Write($buffer, 0, $read)
        }
    } finally {
        if ($output) { $output.Dispose() }
        if ($input) { $input.Dispose() }
        if ($response) { $response.Dispose() }
    }
}

function Assert-CkArchiveHash {
    param(
        [string]$ArchivePath,
        [string]$ChecksumPath,
        [string]$AssetName
    )

    $checksumText = [IO.File]::ReadAllText($ChecksumPath)
    $hashes = @(
        [regex]::Matches(
            $checksumText,
            '(?i)(?<![0-9a-f])[0-9a-f]{64}(?![0-9a-f])'
        ) | ForEach-Object { $_.Value.ToLowerInvariant() } | Select-Object -Unique
    )
    if ($hashes.Count -ne 1) {
        throw "SHA-256 附件必须且只能包含一个有效哈希: $ChecksumPath"
    }
    if ($checksumText -notmatch [regex]::Escape($AssetName)) {
        throw "SHA-256 附件未绑定目标 ZIP 文件名: $AssetName"
    }
    $actual = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $hashes[0]) {
        throw "组件 ZIP 的 SHA-256 不匹配。期望: $($hashes[0])，实际: $actual"
    }
    return $actual
}

function Expand-CkSafeZip {
    param(
        [string]$ArchivePath,
        [string]$Destination
    )

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    $root = [IO.Path]::GetFullPath($Destination).TrimEnd('\') + '\'
    $seen = @{}
    [long]$expandedBytes = 0
    $archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        if ($archive.Entries.Count -gt 100000) {
            throw "组件 ZIP 条目数超过安全上限: $($archive.Entries.Count)"
        }
        foreach ($entry in $archive.Entries) {
            $normalized = $entry.FullName.Replace('\', '/')
            if (
                [string]::IsNullOrWhiteSpace($normalized) -or
                $normalized.StartsWith('/') -or
                $normalized.StartsWith('//') -or
                $normalized -match '^[A-Za-z]:'
            ) {
                throw "组件 ZIP 包含不安全路径: $($entry.FullName)"
            }
            $key = $normalized.TrimEnd('/')
            $parts = @($key.Split('/'))
            if (-not $key -or @($parts | Where-Object { $_ -in @('', '.', '..') }).Count) {
                throw "组件 ZIP 包含不安全路径: $($entry.FullName)"
            }
            if ($seen.ContainsKey($key)) {
                throw "组件 ZIP 包含重复路径: $($entry.FullName)"
            }
            $seen[$key] = $true
            $unixMode = (($entry.ExternalAttributes -shr 16) -band 0xF000)
            if ($unixMode -eq 0xA000) {
                throw "组件 ZIP 包含符号链接: $($entry.FullName)"
            }
            if (
                $entry.Length -gt 1MB -and
                $entry.CompressedLength -gt 0 -and
                ([double]$entry.Length / [double]$entry.CompressedLength) -gt 1000
            ) {
                throw "组件 ZIP 条目压缩比异常: $($entry.FullName)"
            }
            $expandedBytes += $entry.Length
            if ($expandedBytes -gt 1GB) {
                throw '组件 ZIP 解压后超过 1 GB 安全上限。'
            }
            $relative = $normalized.Replace('/', [IO.Path]::DirectorySeparatorChar)
            $target = [IO.Path]::GetFullPath((Join-Path $Destination $relative))
            if (-not $target.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
                throw "组件 ZIP 路径越界: $($entry.FullName)"
            }
            if ($normalized.EndsWith('/')) {
                New-Item -ItemType Directory -Path $target -Force | Out-Null
                continue
            }
            $parent = Split-Path -Parent $target
            if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            $source = $entry.Open()
            $destinationFile = [IO.File]::Open(
                $target,
                [IO.FileMode]::Create,
                [IO.FileAccess]::Write,
                [IO.FileShare]::None
            )
            try {
                $source.CopyTo($destinationFile)
            } finally {
                $destinationFile.Dispose()
                $source.Dispose()
            }
        }
    } finally {
        $archive.Dispose()
    }
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
if ([string]::IsNullOrWhiteSpace($BasePackagePath)) {
    $candidates = @(
        Get-ChildItem -LiteralPath $OutputDirectory -Directory |
            Where-Object { $_.Name -like 'CK免费工具箱-v*' }
    )
    if ($candidates.Count -ne 1) {
        throw "无法唯一确定正式包目录，找到: $($candidates.Count)"
    }
    $BasePackagePath = $candidates[0].FullName
}
$BasePackagePath = [IO.Path]::GetFullPath($BasePackagePath).TrimEnd('\')
if (-not (Test-Path -LiteralPath $BasePackagePath -PathType Container)) {
    throw "正式包目录不存在: $BasePackagePath"
}
$baseManifestPath = Join-Path $BasePackagePath 'package-manifest.json'
if (-not (Test-Path -LiteralPath $baseManifestPath -PathType Leaf)) {
    throw "正式包缺少 package-manifest.json: $BasePackagePath"
}
$baseManifest = Get-Content -LiteralPath $baseManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$releaseVersion = [string]$baseManifest.version
if ($releaseVersion -notmatch '^\d+\.\d+\.\d+$') {
    throw "工具箱版本格式无效: $releaseVersion"
}
$packagePath = $BasePackagePath
$packageName = Split-Path -Leaf $packagePath
$releaseArchivePath = Join-Path $OutputDirectory "$packageName.zip"

$configPath = Join-Path $packagePath 'app\config\tools.json'
$tools = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$bundledComponents = [ordered]@{}
$tempBase = Join-Path ([IO.Path]::GetTempPath()) 'CKFreeToolboxBundledBuild'
New-Item -ItemType Directory -Path $tempBase -Force | Out-Null
$stage = Assert-CkChildPath -Path (Join-Path $tempBase ([Guid]::NewGuid().ToString('N'))) -Parent $tempBase
New-Item -ItemType Directory -Path $stage -Force | Out-Null
$client = New-CkHttpClient
try {
    foreach ($toolId in $ToolIds) {
        $tool = @($tools | Where-Object { [string]$_.id -eq $toolId })[0]
        if (-not $tool -or -not $tool.PSObject.Properties['component']) {
            throw "内置组件配置不存在: $toolId"
        }
        Write-CkStep "获取 $($tool.title) 最新正式 Release"
        $release = Get-CkLatestStableRelease -Client $client -Tool $tool
        Write-Host ("{0}: {1}" -f $toolId, $release.Tag) -ForegroundColor Green

        $componentStage = Join-Path $stage $toolId
        $componentArchivePath = Join-Path $componentStage $release.AssetName
        $checksumPath = Join-Path $componentStage $release.ChecksumName
        $extractPath = Join-Path $componentStage 'extract'
        New-Item -ItemType Directory -Path $componentStage -Force | Out-Null
        Save-CkDownload -Client $client -Url $release.AssetUrl -Destination $componentArchivePath -MaxBytes 512MB
        Save-CkDownload -Client $client -Url $release.ChecksumUrl -Destination $checksumPath -MaxBytes 1MB
        $archiveHash = Assert-CkArchiveHash -ArchivePath $componentArchivePath -ChecksumPath $checksumPath -AssetName $release.AssetName
        Expand-CkSafeZip -ArchivePath $componentArchivePath -Destination $extractPath

        $sourceDirectories = @(Get-ChildItem -LiteralPath $extractPath -Directory)
        $sourceFiles = @(Get-ChildItem -LiteralPath $extractPath -File)
        if ($sourceDirectories.Count -ne 1 -or $sourceFiles.Count -ne 0) {
            throw "组件 ZIP 必须只有一个顶层目录: $toolId"
        }
        $installDir = [string]$tool.component.installDir
        $target = Assert-CkChildPath -Path (Join-Path $packagePath $installDir) -Parent $packagePath
        if (Test-Path -LiteralPath $target) {
            throw "正式包已存在组件目录: $target"
        }
        Move-Item -LiteralPath $sourceDirectories[0].FullName -Destination $target
        foreach ($relative in @($tool.component.requiredFiles)) {
            $required = Assert-CkChildPath -Path (Join-Path $target ([string]$relative)) -Parent $target
            if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
                throw "内置组件缺少必需文件: $toolId/$relative"
            }
        }
        $componentManifest = [ordered]@{
            schemaVersion = 2
            toolId = $toolId
            repo = [string]$tool.component.repo
            releaseTag = [string]$release.Tag
            assetName = [string]$release.AssetName
            sha256 = $archiveHash
            source = 'bundled-github-release'
            installedAt = (Get-Date).ToString('o')
        }
        [IO.File]::WriteAllText(
            (Join-Path $target '.ck-component.json'),
            ($componentManifest | ConvertTo-Json -Depth 4),
            $Utf8NoBom
        )
        $bundledComponents[$toolId] = [ordered]@{
            repo = [string]$release.Repository
            releaseTag = [string]$release.Tag
            assetName = [string]$release.AssetName
            sha256 = $archiveHash
            releaseUrl = [string]$release.HtmlUrl
        }
    }
} finally {
    $client.Dispose()
    if (Test-Path -LiteralPath $stage) {
        $safeStage = Assert-CkChildPath -Path $stage -Parent $tempBase
        Remove-Item -LiteralPath $safeStage -Recurse -Force
    }
}

$manifestPath = Join-Path $packagePath 'package-manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$manifest.flavor = 'standard'
$manifest.bundled.antiJohn = $true
$manifest.bundled.xiaohaCleaner = $true
$manifest | Add-Member -NotePropertyName bundledComponents -NotePropertyValue $bundledComponents -Force
$manifest | Add-Member -NotePropertyName componentsBundledAt -NotePropertyValue ((Get-Date).ToString('o')) -Force
[IO.File]::WriteAllText(
    $manifestPath,
    ($manifest | ConvertTo-Json -Depth 8),
    $Utf8NoBom
)

$guidePath = Join-Path $packagePath '使用说明.txt'
$componentSummary = @(
    '',
    '正式包内置组件：',
    '1. 本正式包已内置“扫描移除后门”和“一键清理小哈”，服务器无需连接 GitHub 即可使用。',
    '2. 两个组件仍需要 Python 3.7+；本包不包含 Python。',
    '3. 内置组件可直接使用；手动点击“在线检查”时才会尝试连接 GitHub。',
    '4. 本包构建时获取的组件版本：'
)
foreach ($toolId in $bundledComponents.Keys) {
    $item = $bundledComponents[$toolId]
    $componentSummary += "   - $toolId $($item.releaseTag) SHA-256 $($item.sha256)"
}
[IO.File]::AppendAllText(
    $guidePath,
    ([Environment]::NewLine + ($componentSummary -join [Environment]::NewLine) + [Environment]::NewLine),
    $Utf8NoBom
)

$packageFiles = @(Get-ChildItem -LiteralPath $packagePath -Recurse -File)
$packageBytes = ($packageFiles | Measure-Object Length -Sum).Sum
Write-Host ("正式发布目录: {0}" -f $packagePath) -ForegroundColor Green
Write-Host ("文件数量: {0}" -f $packageFiles.Count)
Write-Host ("未压缩大小: {0:N2} MB" -f ($packageBytes / 1MB))

if (-not $SkipArchive) {
    Write-CkStep '重新生成内置组件的正式 ZIP'
    Remove-CkBuildArtifact -Path $releaseArchivePath
    Compress-Archive -LiteralPath $packagePath -DestinationPath $releaseArchivePath -CompressionLevel Optimal -Force
    Write-Host ("ZIP: {0}" -f $releaseArchivePath) -ForegroundColor Green
}

[pscustomobject]@{
    version = $releaseVersion
    flavor = 'standard'
    package = $packagePath
    archive = $(if ($SkipArchive) { '' } else { $releaseArchivePath })
    bundledComponents = $bundledComponents
} | ConvertTo-Json -Depth 8 -Compress
