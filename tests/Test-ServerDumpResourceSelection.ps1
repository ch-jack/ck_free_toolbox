[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $repoRoot 'app\pages\ServerDumpPage.ps1')

$single = ConvertTo-CkServerDumpResourceSelectionJson -Target '127.0.0.1:30120' -Resources @('alpha') | ConvertFrom-Json
if ($single.resources -is [string] -or @($single.resources).Count -ne 1 -or [string]$single.resources[0] -cne 'alpha') {
    throw 'A single resource was not serialized as a resources array.'
}

$multiple = ConvertTo-CkServerDumpResourceSelectionJson -Target '127.0.0.1:30120' -Resources @('alpha', 'beta') | ConvertFrom-Json
if (@($multiple.resources).Count -ne 2 -or [string]$multiple.resources[1] -cne 'beta') {
    throw 'Multiple resources were not serialized correctly.'
}

$emptyError = ''
try {
    ConvertTo-CkServerDumpResourceSelectionJson -Target '127.0.0.1:30120' -Resources @() | Out-Null
} catch {
    $emptyError = $_.Exception.Message
}
if (-not $emptyError) {
    throw 'An empty resource selection was not rejected.'
}

Write-Host 'Server dump resource selection serialization tests passed.'
