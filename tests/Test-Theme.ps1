$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$repoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $repoRoot 'app\modules\UiKit.psm1') -Force
Import-Module (Join-Path $repoRoot 'app\modules\ToolboxConfig.psm1') -Force

function Assert-CkThemeTest {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('ck-toolbox-theme-test-' + [Guid]::NewGuid().ToString('N'))
$configPath = Join-Path $tempRoot 'config.json'
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

try {
    $legacyShape = [pscustomobject][ordered]@{
        schemaVersion = 2
        dependencies = [pscustomobject][ordered]@{
            blenderPath = 'C:\Tools\Blender\blender.exe'
            pythonPath = ''
            javaPath = ''
            nodePath = ''
            ffmpegPath = ''
        }
        agreements = [pscustomobject][ordered]@{
            disclaimerAccepted = $true
            disclaimerVersion = 2
            disclaimerAcceptedAt = '2026-08-31T00:00:00+08:00'
        }
    }
    [IO.File]::WriteAllText($configPath, ($legacyShape | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
    [void](Initialize-CkToolboxConfig -Path $configPath)

    $config = Get-CkToolboxConfig
    Assert-CkThemeTest ($config.schemaVersion -eq 2) 'Theme migration changed the established config schema.'
    Assert-CkThemeTest ($config.appearance.theme -eq 'system') 'Legacy config did not receive the system theme default.'
    Assert-CkThemeTest ($config.dependencies.blenderPath -eq 'C:\Tools\Blender\blender.exe') 'Theme migration changed dependency settings.'
    Assert-CkThemeTest ($config.agreements.disclaimerAccepted -eq $true) 'Theme migration changed disclaimer acceptance.'

    [void](Set-CkToolboxThemePreference -Theme light)
    Assert-CkThemeTest ((Get-CkToolboxThemePreference) -eq 'light') 'Light theme preference was not persisted.'
    [void](Set-CkToolboxThemePreference -Theme dark)
    Assert-CkThemeTest ((Get-CkToolboxThemePreference) -eq 'dark') 'Dark theme preference was not persisted.'

    [void](Set-CkTheme -Theme Dark)
    $statusBrush = Get-CkThemeBrush '#31D69A' -Property Foreground
    $root = Import-CkXaml @'
<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Background="#101214" BorderBrush="#242833" BorderThickness="1">
  <Grid>
    <TextBlock x:Name="ThemeText" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Text="主题测试" Foreground="#E5E7EB"/>
    <Ellipse x:Name="ThemeDot" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Width="8" Height="8" Fill="#31D69A"/>
  </Grid>
</Border>
'@
    $text = $root.FindName('ThemeText')
    $dot = $root.FindName('ThemeDot')
    Assert-CkThemeTest ($root.Background.Color.ToString() -eq '#FF10141A') 'Dark surface token was not applied.'
    Assert-CkThemeTest ($text.Foreground.Color.ToString() -eq '#FFEDF1F7') 'Dark text token was not applied.'
    Assert-CkThemeTest ($statusBrush.Color.ToString() -eq '#FF46D6A3') 'Dark runtime status brush was not applied.'

    [void](Set-CkTheme -Theme Light)
    Assert-CkThemeTest ($root.Background.Color.ToString() -eq '#FFFCFDFE') 'Existing surface did not switch to light mode in place.'
    Assert-CkThemeTest ($root.BorderBrush.Color.ToString() -eq '#FFD6DEE9') 'Existing border did not switch to light mode in place.'
    Assert-CkThemeTest ($text.Foreground.Color.ToString() -eq '#FF182230') 'Existing text did not switch to light mode in place.'
    Assert-CkThemeTest ($dot.Fill.Color.ToString() -eq '#FF167552') 'Existing status fill did not switch to light mode in place.'
    Assert-CkThemeTest ($statusBrush.Color.ToString() -eq '#FF167552') 'Runtime status brush did not switch in place.'

    [void](Set-CkTheme -Theme Dark)
    Assert-CkThemeTest ($root.Background.Color.ToString() -eq '#FF10141A') 'Theme could not switch back to dark mode.'

    $shellSource = Get-Content -LiteralPath (Join-Path $repoRoot 'CKFreeToolbox.ps1') -Raw -Encoding UTF8
    foreach ($contract in @(
        'AutomationProperties.AutomationId="Toolbox.ThemeLightButton"',
        'AutomationProperties.AutomationId="Toolbox.ThemeDarkButton"',
        'AutomationProperties.AutomationId="Toolbox.ToolSearchBox"',
        'AutomationProperties.AutomationId="Toolbox.SelfUpdateButton"',
        'AutomationProperties.AutomationId="Toolbox.JoinQqGroupButton"',
        'AutomationProperties.AutomationId="Tool.ComponentActionButton"',
        'AutomationProperties.AutomationId="Tool.OpenSourceButton"'
    )) {
        Assert-CkThemeTest ($shellSource.Contains($contract)) "Shell automation contract missing: $contract"
    }

    Write-Output 'Theme config migration, live switching, runtime brushes, and shell contracts passed.'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
