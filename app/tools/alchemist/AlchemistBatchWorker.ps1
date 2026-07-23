[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CliPath,
    [Parameter(Mandatory)][string]$InputPath,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [Parameter(Mandatory)][string]$ReportPath,
    [string]$FailedDirectory = '',
    [ValidateRange(1, 1024)][int]$Threads = 12,
    [switch]$FailOnError,
    [switch]$Refine,
    [switch]$Relaxed,
    [switch]$Overwrite,
    [switch]$MoveFailed
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

function Get-NormalizedPath {
    param([Parameter(Mandatory)][string]$Path)
    $fullPath = [IO.Path]::GetFullPath($Path)
    $rootPath = [IO.Path]::GetPathRoot($fullPath)
    if ($fullPath.Equals($rootPath, [StringComparison]::OrdinalIgnoreCase)) { return $rootPath }
    return $fullPath.TrimEnd([char[]]@('\', '/'))
}

function Test-CkPathInside {
    param(
        [Parameter(Mandatory)][string]$Candidate,
        [Parameter(Mandatory)][string]$Root
    )
    if ($Candidate.Equals($Root, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    $rootPrefix = $Root.TrimEnd([char[]]@('\', '/')) + [IO.Path]::DirectorySeparatorChar
    return $Candidate.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
}

function Get-CkAvailablePath {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $Path }
    $directory = Split-Path -Parent $Path
    $name = [IO.Path]::GetFileNameWithoutExtension($Path)
    $extension = [IO.Path]::GetExtension($Path)
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    for ($index = 1; $index -le 9999; $index++) {
        $candidate = Join-Path $directory ('{0}.failed-{1}-{2}{3}' -f $name, $stamp, $index, $extension)
        if (-not (Test-Path -LiteralPath $candidate)) { return $candidate }
    }
    throw "Unable to allocate a unique failed-file path: $Path"
}

$script:CkGtaAssetSuffixes = @(
    '.yft', '.ydr', '.ydd', '.ytd', '.ybn', '.ymap', '.ytyp', '.ynv', '.ycd', '.ypt',
    '.yld', '.yed', '.ymf', '.yvr', '.ywr', '.awc', '.rel',
    '.yft.xml', '.ydr.xml', '.ydd.xml', '.ytd.xml', '.ybn.xml', '.ymap.xml',
    '.ytyp.xml', '.ynv.xml', '.ycd.xml', '.ypt.xml', '.yld.xml', '.yed.xml'
)

function Test-CkGtaAssetFile {
    param([Parameter(Mandatory)][IO.FileInfo]$File)

    $name = $File.Name.ToLowerInvariant()
    foreach ($suffix in $script:CkGtaAssetSuffixes) {
        if ($name.EndsWith($suffix, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }

    try {
        $stream = [IO.File]::Open($File.FullName, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        try {
            if ($stream.Length -ge 4) {
                $magicBytes = New-Object byte[] 4
                if ($stream.Read($magicBytes, 0, 4) -eq 4) {
                    $magic = [Text.Encoding]::ASCII.GetString($magicBytes)
                    if ($magic -in @('RSC7', 'RSC8')) { return $true }
                }
            }
        } finally {
            $stream.Dispose()
        }
    } catch { }
    return $false
}

function ConvertTo-CkHtmlText {
    param($Value)
    return [Net.WebUtility]::HtmlEncode([string]$Value)
}

function Write-CkAlchemistReport {
    param(
        [Parameter(Mandatory)][System.Collections.IEnumerable]$Items,
        [Parameter(Mandatory)][datetime]$StartedAt,
        [Parameter(Mandatory)][datetime]$FinishedAt,
        [AllowEmptyString()][string]$FatalError
    )

    $rowHtml = New-Object System.Text.StringBuilder
    foreach ($item in $Items) {
        $statusClass = [string]$item.Status
        $statusLabel = switch ($statusClass) {
            'converted' { 'CONVERTED / &#24050;&#36716;&#25442;' }
            'untouched' { 'UNTOUCHED / &#26410;&#36716;&#25442;&#26410;&#22797;&#21046;' }
            'failed' { 'FAILED / &#22833;&#36133;' }
            'skipped' { 'SKIPPED / &#36339;&#36807;' }
            default { ConvertTo-CkHtmlText $statusClass }
        }
        $errorText = (ConvertTo-CkHtmlText $item.Error) -replace "`r?`n", '<br>'
        [void]$rowHtml.AppendLine(@"
<tr class="$statusClass">
  <td>$(ConvertTo-CkHtmlText $item.RelativePath)</td>
  <td><span class="badge $statusClass">$statusLabel</span></td>
  <td>$(ConvertTo-CkHtmlText $item.OutputPath)</td>
  <td>$(ConvertTo-CkHtmlText $item.FailedPath)</td>
  <td>$errorText</td>
  <td>$([Math]::Round([double]$item.DurationMs)) ms</td>
</tr>
"@)
    }

    $duration = $FinishedAt - $StartedAt
    $operation = if ($Refine) { 'Optimize assets without conversion (--refine)' } else { 'Convert assets' }
    $mode = "$operation; only successful GTA5 asset results are written to output; unconverted files stay in input and are not copied"
    $fatalHtml = if ($FatalError) {
        '<div class="fatal"><strong>Fatal error:</strong> ' + (ConvertTo-CkHtmlText $FatalError) + '</div>'
    } else { '' }
    $failedRoot = if ($MoveFailed) { $FailedDirectory } else { 'Disabled' }
    $html = @"
<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Alchemist &#36716;&#25442;&#25253;&#21578;</title>
<style>
:root{color-scheme:dark;--bg:#0b0d10;--panel:#12151a;--border:#2a3039;--text:#e7eaf0;--muted:#929aa7;--green:#31d69a;--red:#ef7c86;--amber:#f4b860;--blue:#58a6ff}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:14px/1.55 "Segoe UI","Microsoft YaHei",sans-serif}.wrap{max-width:1500px;margin:0 auto;padding:28px}.hero,.panel{background:var(--panel);border:1px solid var(--border);border-radius:12px;padding:22px;margin-bottom:18px}.hero h1{margin:0 0 6px;font-size:28px}.muted{color:var(--muted)}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;margin-top:18px}.card{background:#0e1115;border:1px solid var(--border);border-radius:9px;padding:14px}.value{font-size:26px;font-weight:700}.converted-text{color:var(--green)}.untouched-text{color:var(--blue)}.failed-text{color:var(--red)}.skipped-text{color:var(--amber)}dl{display:grid;grid-template-columns:170px 1fr;gap:8px 14px;margin:0}dt{color:var(--muted)}dd{margin:0;word-break:break-all}.table-wrap{overflow:auto}table{width:100%;border-collapse:collapse;min-width:1100px}th,td{border-bottom:1px solid var(--border);padding:10px;text-align:left;vertical-align:top;word-break:break-all}th{position:sticky;top:0;background:#171b21;color:#bfc6d1}.badge{display:inline-block;border-radius:999px;padding:3px 9px;font-size:12px;font-weight:700;white-space:nowrap}.badge.converted{background:#113a2c;color:var(--green)}.badge.untouched{background:#102440;color:var(--blue)}.badge.failed{background:#3b1b20;color:var(--red)}.badge.skipped{background:#3a2c13;color:var(--amber)}tr.failed{background:rgba(239,124,134,.035)}.fatal{border:1px solid #6f2d36;background:#30171b;color:#ffb5bc;border-radius:8px;padding:13px;margin-top:16px}
</style>
</head>
<body><div class="wrap">
<section class="hero">
  <h1>Alchemist &#36716;&#25442;&#25253;&#21578;</h1>
  <div class="muted">$(ConvertTo-CkHtmlText $StartedAt.ToString('yyyy-MM-dd HH:mm:ss')) - $(ConvertTo-CkHtmlText $FinishedAt.ToString('yyyy-MM-dd HH:mm:ss'))</div>
  <div class="grid">
    <div class="card"><div class="muted">Total / &#24635;&#25968;</div><div class="value">$Total</div></div>
    <div class="card"><div class="muted">Converted / &#24050;&#36716;&#25442;</div><div class="value converted-text">$Converted</div></div>
    <div class="card"><div class="muted">Untouched / &#26410;&#36716;&#25442;&#26410;&#22797;&#21046;</div><div class="value untouched-text">$Untouched</div></div>
    <div class="card"><div class="muted">Failed / &#22833;&#36133;</div><div class="value failed-text">$Failed</div></div>
    <div class="card"><div class="muted">Skipped / &#36339;&#36807;</div><div class="value skipped-text">$Skipped</div></div>
    <div class="card"><div class="muted">Move failed / &#31227;&#21160;&#22833;&#36133;</div><div class="value failed-text">$Unmoved</div></div>
  </div>
  $fatalHtml
</section>
<section class="panel"><dl>
  <dt>Mode / &#27169;&#24335;</dt><dd>$(ConvertTo-CkHtmlText $mode)</dd>
  <dt>Input / &#36755;&#20837;</dt><dd>$(ConvertTo-CkHtmlText $InputPath)</dd>
  <dt>Output / &#36755;&#20986;</dt><dd>$(ConvertTo-CkHtmlText $OutputDirectory)</dd>
  <dt>Failed files / &#22833;&#36133;&#25991;&#20214;</dt><dd>$(ConvertTo-CkHtmlText $failedRoot)</dd>
  <dt>Report / &#25253;&#21578;</dt><dd>$(ConvertTo-CkHtmlText $ReportPath)</dd>
  <dt>Duration / &#32791;&#26102;</dt><dd>$([Math]::Round($duration.TotalSeconds, 2)) s</dd>
</dl></section>
<section class="panel table-wrap"><table>
<thead><tr><th>File / &#25991;&#20214;</th><th>Status / &#29366;&#24577;</th><th>Output / &#36755;&#20986;</th><th>Failed move / &#22833;&#36133;&#31227;&#21160;</th><th>Error / &#38169;&#35823;</th><th>Duration / &#32791;&#26102;</th></tr></thead>
<tbody>$($rowHtml.ToString())</tbody>
</table></section>
</div></body></html>
"@

    $reportParent = Split-Path -Parent $ReportPath
    if ($reportParent) { New-Item -ItemType Directory -Path $reportParent -Force | Out-Null }
    $temporaryReport = "$ReportPath.tmp"
    [IO.File]::WriteAllText($temporaryReport, $html, $utf8Bom)
    Move-Item -LiteralPath $temporaryReport -Destination $ReportPath -Force
}

$CliPath = Get-NormalizedPath $CliPath
$InputPath = Get-NormalizedPath $InputPath
$OutputDirectory = Get-NormalizedPath $OutputDirectory
$ReportPath = [IO.Path]::GetFullPath($ReportPath)
if ($MoveFailed) { $FailedDirectory = Get-NormalizedPath $FailedDirectory }

if (-not (Test-Path -LiteralPath $CliPath -PathType Leaf)) { throw "Alchemist CLI not found: $CliPath" }
if (-not (Test-Path -LiteralPath $InputPath)) { throw "Input not found: $InputPath" }
if (Test-CkPathInside -Candidate $OutputDirectory -Root $InputPath) { throw 'Output must not be inside input.' }
if ($MoveFailed) {
    if (-not $FailedDirectory) { throw 'Failed-directory is required when MoveFailed is enabled.' }
    if (
        (Test-CkPathInside -Candidate $FailedDirectory -Root $InputPath) -or
        (Test-CkPathInside -Candidate $FailedDirectory -Root $OutputDirectory) -or
        (Test-CkPathInside -Candidate $InputPath -Root $FailedDirectory) -or
        (Test-CkPathInside -Candidate $OutputDirectory -Root $FailedDirectory)
    ) {
        throw 'Failed-directory must be separate from input and output.'
    }
}

$inputIsFile = Test-Path -LiteralPath $InputPath -PathType Leaf
$files = if ($inputIsFile) {
    @(Get-Item -LiteralPath $InputPath -Force)
} else {
    @(Get-ChildItem -LiteralPath $InputPath -File -Recurse -Force -ErrorAction Stop | Sort-Object FullName)
}
$inputRoot = if ($inputIsFile) { Split-Path -Parent $InputPath } else { $InputPath }
$inputPrefix = $inputRoot.TrimEnd([char[]]@('\', '/')) + [IO.Path]::DirectorySeparatorChar
$Total = $files.Count
$Success = 0
$Converted = 0
$Untouched = 0
$Failed = 0
$Skipped = 0
$Unmoved = 0
$Processed = 0
$rows = New-Object System.Collections.Generic.List[object]
$startedAt = Get-Date
$fatalError = ''
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('CKFreeToolbox-Alchemist-{0}-{1}' -f $PID, [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

try {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    if ($MoveFailed) { New-Item -ItemType Directory -Path $FailedDirectory -Force | Out-Null }
    Push-Location (Split-Path -Parent $CliPath)
    try {
        foreach ($file in $files) {
            $watch = [Diagnostics.Stopwatch]::StartNew()
            $relativePath = if ($inputIsFile) { $file.Name } else { $file.FullName.Substring($inputPrefix.Length) }
            $targetPath = Join-Path $OutputDirectory $relativePath
            $failedPath = ''
            $status = 'failed'
            $errorMessage = ''
            $isGtaAsset = Test-CkGtaAssetFile -File $file
            $kind = if ($isGtaAsset) { 'asset' } else { 'untouched' }
            Write-Output "[ck-file] index=$($Processed + 1) total=$Total kind=$kind file=$relativePath"

            if (-not $isGtaAsset) {
                $Untouched++
                $status = 'untouched'
                Write-Output "[ck-untouched] file=$relativePath"
            } elseif (Test-Path -LiteralPath $targetPath -PathType Container) {
                $Skipped++
                $status = 'skipped'
                $errorMessage = 'Destination path is a directory.'
            } elseif ((Test-Path -LiteralPath $targetPath) -and -not $Overwrite) {
                $Skipped++
                $status = 'skipped'
                $errorMessage = 'Destination exists and overwrite is disabled.'
            } else {
                $temporaryPath = Join-Path $tempRoot $relativePath
                $temporaryParent = Split-Path -Parent $temporaryPath
                if ($temporaryParent) { New-Item -ItemType Directory -Path $temporaryParent -Force | Out-Null }
                $cliArguments = New-Object System.Collections.Generic.List[object]
                if ($FailOnError) { $cliArguments.Add('--fail-on-error') }
                if ($Refine) { $cliArguments.Add('--refine') }
                if ($Relaxed) { $cliArguments.Add('--relaxed') }
                if ($Overwrite) { $cliArguments.Add('-f') }
                $cliArguments.Add(('-j{0}' -f $Threads))
                $cliArguments.Add($file.FullName)
                $cliArguments.Add($temporaryPath)

                $outputLines = New-Object System.Collections.Generic.List[string]
                [int]$exitCode = -1
                try {
                    & $CliPath @($cliArguments.ToArray()) 2>&1 | ForEach-Object {
                        $line = [string]$_
                        Write-Output $line
                        $outputLines.Add($line)
                    }
                    $exitCode = $LASTEXITCODE
                } catch {
                    $outputLines.Add($_.Exception.Message)
                }

                if ($exitCode -eq 0 -and (Test-Path -LiteralPath $temporaryPath -PathType Leaf)) {
                    try {
                        $targetParent = Split-Path -Parent $targetPath
                        if ($targetParent) { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }
                        Copy-Item -LiteralPath $temporaryPath -Destination $targetPath -Force:$Overwrite -ErrorAction Stop
                        $Converted++
                        $Success++
                        $status = 'converted'
                    } catch {
                        $errorMessage = $_.Exception.Message
                    }
                } else {
                    $tail = @($outputLines | Select-Object -Last 20)
                    $errorMessage = "Alchemist exit code: $exitCode."
                    if ($tail.Count) { $errorMessage += [Environment]::NewLine + ($tail -join [Environment]::NewLine) }
                }

                if ($status -ne 'converted') {
                    $Failed++
                    if ($MoveFailed) {
                        try {
                            $failedPath = Get-CkAvailablePath (Join-Path $FailedDirectory $relativePath)
                            $failedParent = Split-Path -Parent $failedPath
                            if ($failedParent) { New-Item -ItemType Directory -Path $failedParent -Force | Out-Null }
                            Move-Item -LiteralPath $file.FullName -Destination $failedPath -ErrorAction Stop
                        } catch {
                            $Unmoved++
                            $errorMessage = ($errorMessage + [Environment]::NewLine + 'Move failed: ' + $_.Exception.Message).Trim()
                            $failedPath = ''
                        }
                    }
                    Write-Output "[ck-failed] file=$relativePath moved=$failedPath"
                }

                if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
                    Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
                }
            }

            $watch.Stop()
            $Processed++
            $rows.Add([pscustomobject]@{
                RelativePath = $relativePath
                Status = $status
                OutputPath = if ($status -eq 'converted') { $targetPath } else { '' }
                FailedPath = $failedPath
                Error = $errorMessage
                DurationMs = $watch.Elapsed.TotalMilliseconds
            })
            Write-Output "[ck-progress] processed=$Processed total=$Total success=$Success converted=$Converted untouched=$Untouched failed=$Failed skipped=$Skipped unmoved=$Unmoved file=$relativePath"
        }
    } finally {
        Pop-Location
    }
} catch {
    $fatalError = $_.Exception.Message
    Write-Output "[ck-fatal] $fatalError"
} finally {
    $finishedAt = Get-Date
    try {
        Write-CkAlchemistReport -Items $rows -StartedAt $startedAt -FinishedAt $finishedAt -FatalError $fatalError
        Write-Output "[ck-report] path=$ReportPath"
    } catch {
        if (-not $fatalError) { $fatalError = "Report generation failed: $($_.Exception.Message)" }
        Write-Output "[ck-report-error] $($_.Exception.Message)"
    }
    if (Test-Path -LiteralPath $tempRoot -PathType Container) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Output "[ck-summary] total=$Total success=$Success converted=$Converted untouched=$Untouched failed=$Failed skipped=$Skipped unmoved=$Unmoved"
if ($fatalError) { exit 2 }
if ($Failed -gt 0) { exit 1 }
exit 0
