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
        'AutomationProperties.AutomationId="Tool.OpenSourceButton"',
        '$setNavButtonStateAction = (Get-Command Set-CkNavButtonState).ScriptBlock.GetNewClosure()',
        '& $setNavButtonStateAction -Button $buttons[$Id] -Active $true',
        '$updateThemeToggleUiAction = (Get-Command Update-CkThemeToggleUi).ScriptBlock.GetNewClosure()',
        '& $updateThemeToggleUiAction'
    )) {
        Assert-CkThemeTest ($shellSource.Contains($contract)) "Shell automation contract missing: $contract"
    }

    $tokens = $null
    $parseErrors = $null
    $shellAst = [System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $repoRoot 'CKFreeToolbox.ps1'),
        [ref]$tokens,
        [ref]$parseErrors
    )
    Assert-CkThemeTest ($parseErrors.Count -eq 0) 'Shell source could not be parsed for closure regression testing.'
    foreach ($functionName in @('Set-CkNavButtonState','Show-ToolPage')) {
        $functionAst = $shellAst.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName
        }, $true)
        Assert-CkThemeTest ($null -ne $functionAst) "Shell function missing: $functionName"
        . ([scriptblock]::Create($functionAst.Extent.Text))
    }

    $pages = @{
        first = [pscustomobject]@{ Root = New-Object System.Windows.Controls.Grid; Title = '第一页' }
        second = [pscustomobject]@{ Root = New-Object System.Windows.Controls.Grid; Title = '第二页' }
    }
    $pages.first.Root.Visibility = 'Collapsed'
    $pages.second.Root.Visibility = 'Collapsed'
    $buttons = @{
        first = New-Object System.Windows.Controls.Button
        second = New-Object System.Windows.Controls.Button
    }
    foreach ($button in $buttons.Values) {
        $stack = New-Object System.Windows.Controls.StackPanel
        [void]$stack.Children.Add((New-Object System.Windows.Controls.TextBlock))
        [void]$stack.Children.Add((New-Object System.Windows.Controls.TextBlock))
        $button.Content = $stack
    }
    $toolConfigs = @{
        first = [pscustomobject]@{ sourceUrl = 'https://github.com/ch-jack/first' }
        second = [pscustomobject]@{ sourceUrl = 'https://github.com/ch-jack/second' }
    }
    $componentState = [pscustomobject]@{ CurrentToolId = '' }
    $pageTitle = New-Object System.Windows.Controls.TextBlock
    $pageSubtitle = New-Object System.Windows.Controls.TextBlock
    $openSourceButton = New-Object System.Windows.Controls.Button
    $refreshComponentHeaderAction = { }
    $setNavButtonStateAction = (Get-Command Set-CkNavButtonState).ScriptBlock.GetNewClosure()
    $showToolPageAction = (Get-Command Show-ToolPage).ScriptBlock.GetNewClosure()
    & $showToolPageAction -Id first
    & $showToolPageAction -Id second
    Assert-CkThemeTest ($componentState.CurrentToolId -eq 'second') 'Shell page closure did not switch to the requested page.'
    Assert-CkThemeTest ($pages.first.Root.Visibility -eq 'Collapsed') 'Shell page closure did not hide the previous page.'
    Assert-CkThemeTest ($pages.second.Root.Visibility -eq 'Visible') 'Shell page closure did not show the requested page.'

    Write-Output 'Theme migration, live switching, runtime brushes, shell contracts, and navigation closure passed.'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
