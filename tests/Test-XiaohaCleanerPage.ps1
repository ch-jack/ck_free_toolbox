[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('ck-xiaoha-page-' + [Guid]::NewGuid().ToString('N'))
$componentRoot = Join-Path $tempRoot 'xiaoha_cleaner'
$configPath = Join-Path $tempRoot 'config.json'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Import-Module (Join-Path $repoRoot 'app\modules\UiKit.psm1') -Force
Import-Module (Join-Path $repoRoot 'app\modules\ToolboxConfig.psm1') -Force
Import-Module (Join-Path $repoRoot 'app\modules\EnvironmentProbe.psm1') -Force
Import-Module (Join-Path $repoRoot 'app\modules\ProcessRunner.psm1') -Force

try {
    New-Item -ItemType Directory -Path $componentRoot -Force | Out-Null
    [IO.File]::WriteAllBytes((Join-Path $componentRoot 'xiaoha-cleaner.exe'), [byte[]](77, 90, 0, 0))
    [void](Initialize-CkToolboxConfig -Path $configPath)

    $context = [pscustomobject]@{
        Paths = [pscustomobject]@{
            WorkspaceRoot = $tempRoot
            RuntimeRoot = Join-Path $tempRoot 'runtime'
            RendererDir = Join-Path $tempRoot 'vehicle_renderer'
            RenderScript = Join-Path $tempRoot 'vehicle_renderer\render_all_vehicles.py'
            XiaohaCleanerDir = $componentRoot
            XiaohaCleanerExe = Join-Path $componentRoot 'xiaoha-cleaner.exe'
            XiaohaCleanerScript = Join-Path $componentRoot 'xiaoha-cleaner.py'
            DefaultXiaohaCleanerInput = ''
        }
        Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
    }

    . (Join-Path $repoRoot 'app\pages\XiaohaCleanerPage.ps1')
    $page = New-CkXiaohaCleanerPage -Context $context
    if (-not $page -or -not ($page.Root -is [System.Windows.UIElement])) {
        throw 'Xiaoha cleaner page returned an invalid root element.'
    }
    if ([string]$page.Id -cne 'xiaoha-cleaner' -or [string]$page.Title -cne '秒杀小哈') {
        throw 'Xiaoha cleaner page metadata is invalid.'
    }
    foreach ($controlName in @('EnvironmentText', 'PythonDownloadButton', 'PythonBrowseButton', 'ScanButton', 'CleanButton', 'RestoreButton')) {
        if (-not $page.Root.FindName($controlName)) {
            throw "Xiaoha cleaner page is missing control: $controlName"
        }
    }
    $environmentText = $page.Root.FindName('EnvironmentText')
    if ([string]$environmentText.Text -cne '运行环境就绪 · 独立 EXE') {
        throw "Xiaoha cleaner EXE was not preferred: $([string]$environmentText.Text)"
    }
    if (
        [string]$page.Root.FindName('PythonDownloadButton').Visibility -cne 'Collapsed' -or
        [string]$page.Root.FindName('PythonBrowseButton').Visibility -cne 'Collapsed'
    ) {
        throw 'Python controls must be hidden when the standalone EXE is available.'
    }

    $pageSource = Get-Content -LiteralPath (Join-Path $repoRoot 'app\pages\XiaohaCleanerPage.ps1') -Raw -Encoding UTF8
    if ($pageSource -notmatch 'Start-CkLoggedProcess\s+-FileName\s+\(\[string\]\$runtime\.FileName\)') {
        throw 'Xiaoha cleaner page does not invoke the selected runtime.'
    }
    Write-Host 'Xiaoha cleaner WPF page EXE-preference test passed.'
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
