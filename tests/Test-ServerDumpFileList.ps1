[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$pagePath = Join-Path $repoRoot 'app\pages\ServerDumpPage.ps1'
$pageText = [IO.File]::ReadAllText($pagePath, [Text.Encoding]::UTF8)

foreach ($required in @(
    'ServerDump.DownloadFileListButton',
    "'DownloadFileListButton'",
    'function Start-ServerFileList',
    '--list-files',
    '--file-list-output',
    'CK_FILE_LIST',
    '自动打开输出目录'
)) {
    if (-not $pageText.Contains($required)) {
        throw "Server dump file-list integration is missing: $required"
    }
}

$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile($pagePath, [ref]$null, [ref]$errors) | Out-Null
if ($errors.Count) {
    throw "ServerDumpPage.ps1 parse failed: $($errors[0])"
}

Write-Host 'Server dump file-list integration tests passed.'
