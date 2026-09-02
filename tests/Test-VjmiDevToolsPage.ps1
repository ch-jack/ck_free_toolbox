$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$repoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $repoRoot 'app\modules\UiKit.psm1') -Force

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('ck-vjmi-page-' + [Guid]::NewGuid().ToString('N'))
$componentRoot = Join-Path $tempRoot 'arya-fivem-tool'
New-Item -ItemType Directory -Path $componentRoot -Force | Out-Null

try {
    New-Item -ItemType File -Path (Join-Path $componentRoot 'AryaFiveMTool.exe') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $componentRoot 'VERSION'), '1.0.1', (New-Object Text.UTF8Encoding($false)))
    [IO.File]::WriteAllText((Join-Path $componentRoot 'component-manifest.json'), '{"version":"1.0.1"}', (New-Object Text.UTF8Encoding($false)))

    $context = [pscustomobject]@{
        Paths = [pscustomobject]@{
            VjmiDevToolsDir = $componentRoot
            VjmiDevToolsExe = Join-Path $componentRoot 'AryaFiveMTool.exe'
        }
        Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
    }

    . (Join-Path $repoRoot 'app\pages\VjmiDevToolsPage.ps1')
    $page = New-CkVjmiDevToolsPage -Context $context
    if (-not $page -or -not ($page.Root -is [System.Windows.UIElement])) {
        throw 'VJMI DevTools page returned an invalid root element.'
    }
    if ([string]$page.Id -cne 'vjmidevtools' -or [string]$page.Title -cne 'FiveM NUI 调试') {
        throw 'VJMI DevTools page metadata is invalid.'
    }
    foreach ($controlName in @('EnvironmentStatus','ComponentText','FiveMText','AppText','LaunchButton','RefreshButton','OpenComponentButton','OpenDataButton')) {
        if (-not $page.Root.FindName($controlName)) {
            throw "VJMI DevTools page is missing control: $controlName"
        }
    }
    if (-not $page.Root.FindName('LaunchButton').IsEnabled) {
        throw 'Launch button should be enabled for a complete local component fixture.'
    }

    $registry = Get-Content -LiteralPath (Join-Path $repoRoot 'app\config\tools.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $tool = @($registry | Where-Object { [string]$_.id -ceq 'vjmidevtools' })[0]
    if (-not $tool -or [string]$tool.factory -cne 'New-CkVjmiDevToolsPage') {
        throw 'VJMI DevTools registry entry is missing or invalid.'
    }
    if ([string]$tool.component.repo -cne 'ch-jack/vjmidevtools' -or
        [string]$tool.component.installDir -cne 'arya-fivem-tool' -or
        [string]$tool.component.releaseAssetPattern -cne 'vjmidevtools-*-windows-x64.zip' -or
        [string]$tool.component.releaseChecksumAssetPattern -cne 'vjmidevtools-*-windows-x64.zip.sha256') {
        throw 'VJMI DevTools release contract is invalid.'
    }
    foreach ($required in @('AryaFiveMTool.exe','_internal/python312.dll','VERSION','component-manifest.json','NOTICE.md')) {
        if ($required -notin @($tool.component.requiredFiles)) {
            throw "VJMI DevTools required file is not registered: $required"
        }
    }

    $source = Get-Content -LiteralPath (Join-Path $repoRoot 'app\pages\VjmiDevToolsPage.ps1') -Raw -Encoding UTF8
    if (-not $source.Contains('$startInfo.CreateNoWindow = $true') -or
        -not $source.Contains('仅限在您自有或明确获授权的 FiveM 服务器使用')) {
        throw 'VJMI DevTools launch safety contract is missing.'
    }

    Write-Host 'VJMI DevTools WPF page and registry contract passed.'
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
