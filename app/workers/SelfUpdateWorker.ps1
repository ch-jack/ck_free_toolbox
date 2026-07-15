[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('check', 'prepare')][string]$Action,
    [Parameter(Mandatory)][string]$CurrentVersion,
    [Parameter(Mandatory)][string]$InstallRoot
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repository = 'ch-jack/ck_free_toolbox'
$UserAgent = 'CKFreeToolbox/1.0.2'

function Write-CkSelfProgress {
    param([int]$Percent, [string]$Message)

    $payload = [ordered]@{
        percent = [Math]::Max(0, [Math]::Min(100, $Percent))
        message = $Message
    } | ConvertTo-Json -Compress
    [Console]::Out.WriteLine("CK_SELF_PROGRESS $payload")
}

function Assert-CkChildPath {
    param([string]$Path, [string]$Parent)

    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $fullParent = [IO.Path]::GetFullPath($Parent).TrimEnd([IO.Path]::DirectorySeparatorChar)
    if (-not $fullPath.StartsWith($fullParent + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "更新路径越界: $fullPath"
    }
    return $fullPath
}

function Remove-CkDirectory {
    param([string]$Path, [string]$Parent)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return }
    $safePath = Assert-CkChildPath -Path $Path -Parent $Parent
    [IO.Directory]::Delete($safePath, $true)
}

function Test-CkHttpAsset {
    param([Net.Http.HttpClient]$Client, [string]$Url)

    $request = New-Object Net.Http.HttpRequestMessage([Net.Http.HttpMethod]::Head, $Url)
    $response = $null
    try {
        $response = $Client.SendAsync($request, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
        return $response.IsSuccessStatusCode
    } finally {
        if ($response) { $response.Dispose() }
        $request.Dispose()
    }
}

function Get-CkLatestRelease {
    Add-Type -AssemblyName System.Net.Http
    $client = New-Object Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromSeconds(30)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd($UserAgent)
    $response = $null
    try {
        $latestUrl = "https://github.com/$Repository/releases/latest"
        $response = $client.GetAsync($latestUrl, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
        if (-not $response.IsSuccessStatusCode) {
            throw '工具箱尚未发布稳定 Release。'
        }

        $releaseUri = $response.RequestMessage.RequestUri
        if ($releaseUri.Scheme -ne 'https' -or $releaseUri.Host -ne 'github.com') {
            throw "GitHub Release 跳转地址无效: $releaseUri"
        }
        $segments = @($releaseUri.AbsolutePath.Trim('/').Split('/'))
        $repoParts = $Repository.Split('/')
        if ($segments.Count -ne 5 -or
            $segments[0] -ine $repoParts[0] -or
            $segments[1] -ine $repoParts[1] -or
            $segments[2] -ine 'releases' -or
            $segments[3] -ine 'tag') {
            throw "GitHub 最新 Release 跳转结构无效: $releaseUri"
        }

        $tag = [Uri]::UnescapeDataString($segments[4])
        if ($tag -notmatch '^v([0-9]+\.[0-9]+\.[0-9]+)$') {
            throw "工具箱 Release 标签格式无效: $tag"
        }
        $version = $Matches[1]
        $assetName = "CK-Free-Toolbox-$tag.zip"
        $escapedTag = [Uri]::EscapeDataString($tag)
        $assetUrl = "https://github.com/$Repository/releases/download/$escapedTag/$([Uri]::EscapeDataString($assetName))"
        if (-not (Test-CkHttpAsset -Client $client -Url $assetUrl)) {
            throw "工具箱 Release 缺少附件: $assetName"
        }

        $checksumName = "$assetName.sha256"
        $checksumUrl = "https://github.com/$Repository/releases/download/$escapedTag/$([Uri]::EscapeDataString($checksumName))"
        $hasChecksum = Test-CkHttpAsset -Client $client -Url $checksumUrl
        return [pscustomobject]@{
            Tag = $tag
            Version = $version
            AssetName = $assetName
            AssetUrl = $assetUrl
            ChecksumName = $checksumName
            ChecksumUrl = $(if ($hasChecksum) { $checksumUrl } else { '' })
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
        [long]$MaxBytes,
        [int]$StartPercent,
        [int]$EndPercent,
        [string]$Label
    )

    $uri = [Uri]$Url
    if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'github.com') {
        throw "拒绝非 GitHub 下载地址: $Url"
    }

    Add-Type -AssemblyName System.Net.Http
    $client = New-Object Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromMinutes(10)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd($UserAgent)
    $response = $null
    $input = $null
    $output = $null
    try {
        $response = $client.GetAsync($uri, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
        $response.EnsureSuccessStatusCode() | Out-Null
        $length = $response.Content.Headers.ContentLength
        if ($length -and $length -gt $MaxBytes) { throw "下载超过大小限制: $length bytes" }

        $input = $response.Content.ReadAsStreamAsync().Result
        $output = [IO.File]::Open($Destination, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $buffer = New-Object byte[] 1048576
        [long]$total = 0
        $lastPercent = -1
        Write-CkSelfProgress -Percent $StartPercent -Message $Label
        while (($read = $input.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $total += $read
            if ($total -gt $MaxBytes) { throw "下载超过大小限制: $MaxBytes bytes" }
            $output.Write($buffer, 0, $read)
            if ($length -and $length -gt 0) {
                $percent = $StartPercent + [int](($total / $length) * ($EndPercent - $StartPercent))
                $percent = [Math]::Min($EndPercent, $percent)
                if ($percent -gt $lastPercent) {
                    Write-CkSelfProgress -Percent $percent -Message ("$Label {0:N1}/{1:N1} MB" -f ($total / 1MB), ($length / 1MB))
                    $lastPercent = $percent
                }
            }
        }
        Write-CkSelfProgress -Percent $EndPercent -Message "$Label 完成"
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
    $separator = [IO.Path]::DirectorySeparatorChar
    $destinationRoot = [IO.Path]::GetFullPath($Destination).TrimEnd($separator) + $separator
    $archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    [long]$totalBytes = ($archive.Entries | Measure-Object -Property Length -Sum).Sum
    [long]$expandedBytes = 0
    $lastPercent = 65
    Write-CkSelfProgress -Percent 65 -Message '正在解压更新包'
    try {
        foreach ($entry in $archive.Entries) {
            $expandedBytes += $entry.Length
            if ($expandedBytes -gt 536870912) { throw '更新包解压后超过 512 MB 限制。' }
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
                $percent = 65 + [int](($expandedBytes / $totalBytes) * 13)
                if ($percent -gt $lastPercent) {
                    Write-CkSelfProgress -Percent ([Math]::Min(78, $percent)) -Message '正在解压更新包'
                    $lastPercent = $percent
                }
            }
        }
    } finally {
        $archive.Dispose()
    }
    Write-CkSelfProgress -Percent 78 -Message '更新包解压完成'
}

function Assert-CkPackage {
    param([string]$PackageRoot, $Release, [string]$ArchiveHash)

    $manifestPath = Join-Path $PackageRoot 'package-manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw '更新包缺少 package-manifest.json。'
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$manifest.version -ne [string]$Release.Version) {
        throw "更新包版本不匹配: $($manifest.version) != $($Release.Version)"
    }

    $required = @(
        'CK免费工具箱.exe',
        'CKFreeToolbox.ps1',
        'app\modules\ToolboxConfig.psm1',
        'app\config\tools.json',
        'app\workers\ComponentWorker.ps1',
        'app\workers\SelfUpdateWorker.ps1',
        'app\workers\ApplyToolboxUpdate.ps1',
        'static\cklogo.ico'
    )
    foreach ($relative in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $PackageRoot $relative) -PathType Leaf)) {
            throw "更新包缺少核心文件: $relative"
        }
    }

    $hashChecks = [ordered]@{
        executable = 'CK免费工具箱.exe'
        mainScript = 'CKFreeToolbox.ps1'
        toolboxConfig = 'app\modules\ToolboxConfig.psm1'
        componentWorker = 'app\workers\ComponentWorker.ps1'
        selfUpdateWorker = 'app\workers\SelfUpdateWorker.ps1'
        applyUpdateWorker = 'app\workers\ApplyToolboxUpdate.ps1'
    }
    foreach ($name in $hashChecks.Keys) {
        if (-not $manifest.sha256.PSObject.Properties[$name]) {
            throw "更新清单缺少哈希字段: $name"
        }
        $actual = (Get-FileHash -LiteralPath (Join-Path $PackageRoot $hashChecks[$name]) -Algorithm SHA256).Hash
        $expected = [string]$manifest.sha256.$name
        if ($actual -ine $expected) {
            throw "更新包文件校验失败: $($hashChecks[$name])"
        }
    }
    return [pscustomobject]@{ Manifest = $manifest; ArchiveHash = $ArchiveHash }
}

function Copy-CkPackageToStage {
    param([string]$Source, [string]$Destination)

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    foreach ($item in @(Get-ChildItem -LiteralPath $Source -Force)) {
        Copy-Item -LiteralPath $item.FullName -Destination $Destination -Recurse -Force
    }
}

try {
    $install = [IO.Path]::GetFullPath($InstallRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $install -PathType Container)) {
        throw "工具箱安装目录不存在: $install"
    }
    if ($CurrentVersion -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') {
        throw "当前工具箱版本无效: $CurrentVersion"
    }

    Write-CkSelfProgress -Percent 3 -Message '正在读取本地版本'
    Write-CkSelfProgress -Percent 10 -Message '正在连接 GitHub Release'
    $release = Get-CkLatestRelease
    $updateAvailable = ([version]$release.Version -gt [version]$CurrentVersion)
    Write-CkSelfProgress -Percent $(if ($Action -eq 'check') { 88 } else { 18 }) -Message "最新版本 $($release.Tag)"

    $result = [ordered]@{
        schemaVersion = 1
        action = $Action
        currentVersion = $CurrentVersion
        latestVersion = [string]$release.Tag
        releaseUrl = [string]$release.HtmlUrl
        releaseAsset = [string]$release.AssetName
        updateAvailable = $updateAvailable
        archiveSha256 = ''
        stagePath = ''
        updaterPath = ''
        status = $(if ($updateAvailable) { 'update-available' } else { 'current' })
    }

    if ($Action -eq 'prepare' -and $updateAvailable) {
        $downloadBase = Join-Path ([IO.Path]::GetTempPath()) 'CKFreeToolbox'
        New-Item -ItemType Directory -Path $downloadBase -Force | Out-Null
        $downloadStage = Assert-CkChildPath -Path (Join-Path $downloadBase ('self-update-' + [Guid]::NewGuid().ToString('N'))) -Parent $downloadBase
        $archivePath = Join-Path $downloadStage 'toolbox.zip'
        $extractPath = Join-Path $downloadStage 'extract'
        New-Item -ItemType Directory -Path $downloadStage -Force | Out-Null
        $targetStage = ''
        try {
            Save-CkDownload -Url $release.AssetUrl -Destination $archivePath -MaxBytes 268435456 -StartPercent 20 -EndPercent 58 -Label '正在下载工具箱更新'
            $archiveHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($release.ChecksumUrl) {
                $checksumPath = Join-Path $downloadStage 'toolbox.zip.sha256'
                Save-CkDownload -Url $release.ChecksumUrl -Destination $checksumPath -MaxBytes 1048576 -StartPercent 59 -EndPercent 60 -Label '正在下载校验文件'
                $checksumText = [IO.File]::ReadAllText($checksumPath)
                $match = [regex]::Match($checksumText, '(?i)(?<![0-9a-f])[0-9a-f]{64}(?![0-9a-f])')
                if (-not $match.Success -or $match.Value.ToLowerInvariant() -ne $archiveHash) {
                    throw '工具箱更新 ZIP 的 SHA-256 校验失败。'
                }
            }
            Write-CkSelfProgress -Percent 63 -Message '更新包下载校验通过'
            Expand-CkSafeZip -ArchivePath $archivePath -Destination $extractPath

            $topDirectories = @(Get-ChildItem -LiteralPath $extractPath -Directory)
            $topFiles = @(Get-ChildItem -LiteralPath $extractPath -File)
            if ($topDirectories.Count -ne 1 -or $topFiles.Count -ne 0) {
                throw '工具箱更新 ZIP 顶层结构无效。'
            }
            $packageRoot = $topDirectories[0].FullName
            Write-CkSelfProgress -Percent 82 -Message '正在验证工具箱核心文件'
            [void](Assert-CkPackage -PackageRoot $packageRoot -Release $release -ArchiveHash $archiveHash)
            Write-CkSelfProgress -Percent 89 -Message '工具箱核心文件验证通过'

            $updateRoot = Join-Path $install '.ck-self-update'
            New-Item -ItemType Directory -Path $updateRoot -Force | Out-Null
            $targetStage = Assert-CkChildPath -Path (Join-Path $updateRoot ("stage-$($release.Tag)-" + [Guid]::NewGuid().ToString('N').Substring(0, 8))) -Parent $updateRoot
            $payloadRoot = Join-Path $targetStage 'payload'
            Write-CkSelfProgress -Percent 92 -Message '正在准备替换文件'
            Copy-CkPackageToStage -Source $packageRoot -Destination $payloadRoot

            $updaterRoot = Join-Path $downloadBase 'updaters'
            New-Item -ItemType Directory -Path $updaterRoot -Force | Out-Null
            $updaterPath = Join-Path $updaterRoot ("ApplyToolboxUpdate-$([Guid]::NewGuid().ToString('N')).ps1")
            Copy-Item -LiteralPath (Join-Path $packageRoot 'app\workers\ApplyToolboxUpdate.ps1') -Destination $updaterPath -Force

            $result.archiveSha256 = $archiveHash
            $result.stagePath = $payloadRoot
            $result.updaterPath = $updaterPath
            $result.status = 'prepared'
            Write-CkSelfProgress -Percent 100 -Message '更新已就绪，正在重启'
        } catch {
            if ($targetStage -and (Test-Path -LiteralPath $targetStage -PathType Container)) {
                Remove-CkDirectory -Path $targetStage -Parent (Join-Path $install '.ck-self-update')
            }
            throw
        } finally {
            if (Test-Path -LiteralPath $downloadStage -PathType Container) {
                Remove-CkDirectory -Path $downloadStage -Parent $downloadBase
            }
        }
    } else {
        Write-CkSelfProgress -Percent 100 -Message $(if ($updateAvailable) { "发现新版本 $($release.Tag)" } else { '当前已是最新版本' })
    }

    $result | ConvertTo-Json -Depth 5 -Compress
    exit 0
} catch {
    [ordered]@{
        schemaVersion = 1
        action = $Action
        status = 'error'
        error = $_.Exception.Message
    } | ConvertTo-Json -Compress
    exit 1
}
