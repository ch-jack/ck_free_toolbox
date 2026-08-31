$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

$repoRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path -Parent $repoRoot
$appRoot = Join-Path $repoRoot 'app'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('ck-toolbox-pages-test-' + [Guid]::NewGuid().ToString('N'))
$configPath = Join-Path $tempRoot 'config.json'
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

Import-Module (Join-Path $appRoot 'modules\UiKit.psm1') -Force
Import-Module (Join-Path $appRoot 'modules\AssetScanner.psm1') -Force
Import-Module (Join-Path $appRoot 'modules\ToolboxConfig.psm1') -Force
Import-Module (Join-Path $appRoot 'modules\EnvironmentProbe.psm1') -Force
Import-Module (Join-Path $appRoot 'modules\ProcessRunner.psm1') -Force
[void](Initialize-CkToolboxConfig -Path $configPath)

function Assert-CkPageThemeTest {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$context = [pscustomobject]@{
    Paths = [pscustomobject]@{
        ScriptRoot = $repoRoot
        AppRoot = $appRoot
        UserConfig = $configPath
        WorkspaceRoot = $workspaceRoot
        RuntimeRoot = Join-Path $workspaceRoot 'runtime'
        RendererDir = Join-Path $workspaceRoot 'vehicle_renderer'
        RenderScript = Join-Path $workspaceRoot 'vehicle_renderer\render_all_vehicles.py'
        WallfixDir = Join-Path $workspaceRoot 'nui-wallfix'
        WallfixScript = Join-Path $workspaceRoot 'nui-wallfix\nui-wallfix.py'
        WallfixProviders = Join-Path $workspaceRoot 'nui-wallfix\providers.json'
        RpfToFivemDir = Join-Path $workspaceRoot 'rpf_to_fivem'
        RpfToFivemScript = Join-Path $workspaceRoot 'rpf_to_fivem\rpf_to_fivem.py'
        ModelToolsDir = Join-Path $workspaceRoot 'fivem_model_tools'
        ModelToolsScript = Join-Path $workspaceRoot 'fivem_model_tools\fivem-model-tools.py'
        DumpToolDir = Join-Path $workspaceRoot 'dump-tool'
        DumpToolScript = Join-Path $workspaceRoot 'dump-tool\auto.py'
        FxapDecryptorDir = Join-Path $workspaceRoot 'fxap-decryptor'
        FxapDecryptorScript = Join-Path $workspaceRoot 'fxap-decryptor\index.js'
        AntiJohnDir = Join-Path $workspaceRoot 'ck_anti_john'
        AntiJohnScript = Join-Path $workspaceRoot 'ck_anti_john\ck-anti-john.py'
        XiaohaCleanerDir = Join-Path $workspaceRoot 'xiaoha_cleaner'
        XiaohaCleanerExe = Join-Path $workspaceRoot 'xiaoha_cleaner\xiaoha-cleaner.exe'
        XiaohaCleanerScript = Join-Path $workspaceRoot 'xiaoha_cleaner\xiaoha-cleaner.py'
        SnowyMergerDir = Join-Path $workspaceRoot 'snowy-merger'
        SnowyMergerExe = Join-Path $workspaceRoot 'snowy-merger\YmapMerger.exe'
        ClothingRepackerDir = Join-Path $workspaceRoot 'red40-clothing-packer'
        ClothingRepackerExe = Join-Path $workspaceRoot 'red40-clothing-packer\ClothingRepacker.Cli.exe'
        ImageCompressorDir = Join-Path $workspaceRoot 'fivem-compression-img'
        ImageCompressorScript = Join-Path $workspaceRoot 'fivem-compression-img\fivem-compression-img.py'
        DefaultWallfixInput = ''
        DefaultRpfInput = ''
        DefaultAntiJohnInput = ''
        DefaultXiaohaCleanerInput = ''
        DefaultRpfOutput = Join-Path $tempRoot 'RpfToFivemOutput'
        DefaultModelToolsInput = ''
        DefaultModelToolsOutput = Join-Path $tempRoot 'ExtractedModelResources'
        DefaultServerDumpOutput = Join-Path $tempRoot 'ServerDumpOutput'
        DefaultSnowyMergerOutput = Join-Path $tempRoot 'SnowyMergerOutput'
        DefaultClothingRepackerWork = Join-Path $tempRoot 'ClothingRepackerWork'
        DefaultImageCompressorInput = ''
        DefaultImageCompressorOutput = Join-Path $tempRoot 'ImageCompressionOutput'
        DefaultInput = Join-Path $workspaceRoot 'TestVeh'
        DefaultRenderOut = Join-Path $tempRoot 'VehicleRenders'
    }
    Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
}

try {
    [void](Set-CkTheme -Theme Dark)
    $registry = Get-Content -LiteralPath (Join-Path $appRoot 'config\tools.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $tools = @()
    foreach ($registeredTool in $registry) { $tools += $registeredTool }
    Assert-CkPageThemeTest ($tools.Count -eq 12) "Expected 12 registered tools, found $($tools.Count)."

    $pages = @{}
    $darkSamples = @{}
    foreach ($tool in $tools) {
        $pagePath = Join-Path (Join-Path $appRoot 'pages') ([string]$tool.page)
        . $pagePath
        $page = & ([string]$tool.factory) -Context $context
        if ($page -is [System.Windows.UIElement]) {
            $page = [pscustomobject]@{ Root = $page; Title = [string]$tool.title }
        }
        Assert-CkPageThemeTest ($page -and $page.Root -is [System.Windows.UIElement]) "Invalid page root: $($tool.id)"
        $themeKeys = @($page.Root.Resources.Keys | Where-Object { ([string]$_).StartsWith('CkTheme_', [StringComparison]::Ordinal) })
        Assert-CkPageThemeTest ($themeKeys.Count -gt 0) "No theme resources injected: $($tool.id)"
        $sampleColors = @{}
        foreach ($themeKey in $themeKeys) {
            $sampleBrush = $page.Root.Resources[$themeKey]
            Assert-CkPageThemeTest ($sampleBrush -is [System.Windows.Media.SolidColorBrush]) "Invalid theme brush: $($tool.id)"
            $sampleColors[[string]$themeKey] = $sampleBrush.Color.ToString()
        }
        $pages[[string]$tool.id] = $page
        $darkSamples[[string]$tool.id] = $sampleColors
    }

    [void](Set-CkTheme -Theme Light)
    $changed = 0
    foreach ($tool in $tools) {
        $id = [string]$tool.id
        $page = $pages[$id]
        $pageChanged = $false
        foreach ($themeKey in $darkSamples[$id].Keys) {
            $lightColor = $page.Root.Resources[$themeKey].Color.ToString()
            if ($lightColor -ne $darkSamples[$id][$themeKey]) {
                $pageChanged = $true
                break
            }
        }
        if ($pageChanged) { $changed++ }
        Assert-CkPageThemeTest ($page.Root -is [System.Windows.UIElement]) "Page root was replaced during theme switch: $id"
    }
    Assert-CkPageThemeTest ($changed -eq $tools.Count) "Only $changed/$($tools.Count) page roots reacted to the theme switch."

    Write-Output "All $($tools.Count) page factories instantiated and switched themes in place."
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
