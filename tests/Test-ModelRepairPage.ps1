# Run with Windows PowerShell 5.1: powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File tests\Test-ModelRepairPage.ps1
#requires -Version 5.1
$ErrorActionPreference = 'Stop'

if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne [Threading.ApartmentState]::STA) {
    throw 'Run this test with powershell.exe -STA.'
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

$repoRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path -Parent $repoRoot
$appRoot = Join-Path $repoRoot 'app'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('ck-model-repair-page-' + [Guid]::NewGuid().ToString('N'))
$configPath = Join-Path $tempRoot 'config.json'
$assertions = 0

function Assert-ModelRepairPage {
    param([bool]$Condition, [string]$Message)
    $script:assertions++
    if (-not $Condition) { throw $Message }
}

function New-ModelRepairOutputStateFixture {
    return [pscustomobject]@{
        NativeLogPath = ''
        Total = 0
        Current = 0
        Scanned = 0
        Repaired = 0
        Skipped = 0
        Failed = 0
        SummarySeen = $false
    }
}

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    Import-Module (Join-Path $appRoot 'modules\UiKit.psm1') -Force
    Import-Module (Join-Path $appRoot 'modules\ToolboxConfig.psm1') -Force
    Import-Module (Join-Path $appRoot 'modules\EnvironmentProbe.psm1') -Force
    Import-Module (Join-Path $appRoot 'modules\ProcessRunner.psm1') -Force
    [void](Initialize-CkToolboxConfig -Path $configPath)

    $componentRoot = Join-Path $workspaceRoot 'fxap-decryptor'
    $repairRoot = Join-Path $componentRoot 'tools\vertex-fixer'
    $repairExe = Join-Path $repairRoot 'FivemDecryptFixer.Cli.exe'
    $context = [pscustomobject]@{
        Paths = [pscustomobject]@{
            WorkspaceRoot = $workspaceRoot
            FxapDecryptorDir = $componentRoot
            ModelRepairDir = $repairRoot
            ModelRepairExe = $repairExe
        }
        Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
    }

    . (Join-Path $appRoot 'pages\ModelRepairPage.ps1')

    $emptyResult = Resolve-CkModelRepairResult -ExitCode 0 -Cancelled $false -Scanned 0 -Repaired 0 -Skipped 0 -Failed 0
    Assert-ModelRepairPage ($emptyResult.Status -ceq 'empty') 'Exit code 0 with no scanned models must resolve to empty.'

    $failedSummaryResult = Resolve-CkModelRepairResult -ExitCode 0 -Cancelled $false -Scanned 3 -Repaired 1 -Skipped 1 -Failed 1
    Assert-ModelRepairPage ($failedSummaryResult.Status -ceq 'partial') 'A non-zero failed count must take precedence over exit code 0.'
    Assert-ModelRepairPage ($failedSummaryResult.ResultText -ceq '完成，存在失败') 'Partial result must use the warning UI state.'

    $partialFallbackResult = Resolve-CkModelRepairResult -ExitCode 1 -Cancelled $false -Scanned 2 -Repaired 2 -Skipped 0 -Failed 0
    Assert-ModelRepairPage ($partialFallbackResult.Status -ceq 'partial') 'Exit code 1 with processed models must resolve to partial.'

    $fatalState = New-ModelRepairOutputStateFixture
    $fatalEvent = Update-CkModelRepairOutputState -State $fatalState -Line '[MODEL FATAL] native bridge failed'
    $fatalResult = Resolve-CkModelRepairResult -ExitCode 2 -Cancelled $false -Scanned $fatalState.Scanned -Repaired $fatalState.Repaired -Skipped $fatalState.Skipped -Failed $fatalState.Failed
    Assert-ModelRepairPage ($fatalEvent.Kind -ceq 'fatal' -and $fatalEvent.Message -ceq 'native bridge failed') 'Fatal output must be parsed with its message.'
    Assert-ModelRepairPage ($fatalResult.Status -ceq 'failed') 'Fatal output without a summary must resolve to failed.'

    $cancelledResult = Resolve-CkModelRepairResult -ExitCode 1 -Cancelled $true -Scanned 4 -Repaired 2 -Skipped 1 -Failed 1
    Assert-ModelRepairPage ($cancelledResult.Status -ceq 'cancelled') 'Cancellation must take precedence over output and exit-code state.'

    $noWorkFailure = Resolve-CkModelRepairResult -ExitCode 0 -Cancelled $false -Scanned 0 -Repaired 0 -Skipped 0 -Failed 1
    Assert-ModelRepairPage ($noWorkFailure.Status -ceq 'failed') 'A failed count without processed work must resolve to failed.'

    $parsedState = New-ModelRepairOutputStateFixture
    $progressEvent = Update-CkModelRepairOutputState -State $parsedState -Line '[MODEL 1/3] D:\模型\car.yft'
    Assert-ModelRepairPage ($progressEvent.Kind -ceq 'progress' -and $parsedState.Scanned -eq 1 -and $parsedState.Total -eq 3) 'Progress output was not parsed into counters.'
    [void](Update-CkModelRepairOutputState -State $parsedState -Line '[MODEL] scanned=3, repaired=1, failed=1')
    Assert-ModelRepairPage ($parsedState.SummarySeen -and $parsedState.Scanned -eq 3 -and $parsedState.Repaired -eq 1 -and $parsedState.Skipped -eq 1 -and $parsedState.Failed -eq 1) 'Final summary was not applied to parser state.'
    [void](Update-CkModelRepairOutputState -State $parsedState -Line '[MODEL ERROR] late stderr duplicate')
    Assert-ModelRepairPage ($parsedState.Failed -eq 1) 'A late stderr error after the stdout summary must not be double-counted.'

    $detachedUpdateAction = (Get-Command Update-CkModelRepairOutputState).ScriptBlock.GetNewClosure()
    $detachedResolveAction = (Get-Command Resolve-CkModelRepairResult).ScriptBlock.GetNewClosure()
    $detachedCallback = {
        param($CallbackState)
        [void](& $detachedUpdateAction -State $CallbackState -Line '[MODEL] scanned=1, repaired=1, failed=0')
        return & $detachedResolveAction -ExitCode 0 -Cancelled $false -Scanned $CallbackState.Scanned `
            -Repaired $CallbackState.Repaired -Skipped $CallbackState.Skipped -Failed $CallbackState.Failed
    }.GetNewClosure()
    Remove-Item -LiteralPath Function:\Update-CkModelRepairOutputState
    Remove-Item -LiteralPath Function:\Resolve-CkModelRepairResult
    $detachedState = New-ModelRepairOutputStateFixture
    $detachedResult = & $detachedCallback $detachedState
    Assert-ModelRepairPage ($detachedState.SummarySeen -and $detachedResult.Status -ceq 'success') 'Captured parser and resolver must remain callable after their defining functions leave callback scope.'
    . (Join-Path $appRoot 'pages\ModelRepairPage.ps1')

    $page = New-CkModelRepairPage -Context $context
    Assert-ModelRepairPage ($page -and $page.Root -is [System.Windows.UIElement]) 'Model repair page returned an invalid root element.'
    Assert-ModelRepairPage ([string]$page.Id -ceq 'model-repair') 'Model repair page id is invalid.'
    Assert-ModelRepairPage ([string]$page.Title -ceq '模型修复') 'Model repair page title is invalid.'
    Assert-ModelRepairPage ([string]$page.Icon -ceq '◈') 'Model repair page icon is invalid.'

    foreach ($controlName in @(
        'EnvironmentStatus','TargetBox','ChooseFolderButton','OpenFolderButton','StartButton','StopButton',
        'ScannedCount','RepairedCount','SkippedCount','FailedCount','ProgressBar','StatusLine','LogBox',
        'OpenNativeLogButton','OpenReportButton','OpenReportHistoryButton'
    )) {
        Assert-ModelRepairPage ($null -ne $page.Root.FindName($controlName)) "Model repair page is missing control: $controlName"
    }

    $registry = Get-Content -LiteralPath (Join-Path $appRoot 'config\tools.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $modelTool = @($registry | Where-Object { $_.id -eq 'model-repair' })
    $fxapTool = @($registry | Where-Object { $_.id -eq 'fxap-decryptor' })
    Assert-ModelRepairPage ($modelTool.Count -eq 1) 'tools.json must contain exactly one model-repair entry.'
    Assert-ModelRepairPage ($fxapTool.Count -eq 1) 'tools.json must contain exactly one fxap-decryptor entry.'
    Assert-ModelRepairPage ([string]$modelTool[0].component.repo -ceq [string]$fxapTool[0].component.repo) 'Model repair must reuse the FXAP component repository.'
    Assert-ModelRepairPage ([string]$modelTool[0].component.installDir -ceq [string]$fxapTool[0].component.installDir) 'Model repair must reuse the FXAP component install directory.'
    Assert-ModelRepairPage (@($modelTool[0].component.requiredFiles) -contains 'tools/vertex-fixer/FivemDecryptFixer.Cli.exe') 'Model repair component requirements are missing the CLI.'
    Assert-ModelRepairPage (@($modelTool[0].component.requiredFiles) -contains 'tools/vertex-fixer/CK.VertexBridge.dll') 'Model repair component requirements are missing the native bridge.'

    $mainPath = Join-Path $repoRoot 'CKFreeToolbox.ps1'
    $mainTokens = $null
    $mainErrors = $null
    $mainAst = [Management.Automation.Language.Parser]::ParseFile($mainPath, [ref]$mainTokens, [ref]$mainErrors)
    Assert-ModelRepairPage (@($mainErrors).Count -eq 0) 'CKFreeToolbox.ps1 must parse before testing component identity.'
    $componentKeyAst = $mainAst.Find({
        param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Get-CkComponentKey'
    }, $true)
    Assert-ModelRepairPage ($null -ne $componentKeyAst) 'CKFreeToolbox.ps1 is missing Get-CkComponentKey.'
    $componentKeyScript = [scriptblock]::Create([string]$componentKeyAst.Extent.Text)
    . $componentKeyScript
    $modelComponentKey = Get-CkComponentKey -Tool $modelTool[0]
    $fxapComponentKey = Get-CkComponentKey -Tool $fxapTool[0]
    $unrelatedTool = @($registry | Where-Object { $_.id -eq 'model-render' })[0]
    Assert-ModelRepairPage ($modelComponentKey -ceq $fxapComponentKey) 'FXAP decryptor and model repair must share one component identity key.'
    Assert-ModelRepairPage ($modelComponentKey -cne (Get-CkComponentKey -Tool $unrelatedTool)) 'Unrelated tools must not share the FXAP component identity key.'

    $queuedKeys = @{}
    $queuedIds = New-Object System.Collections.Generic.List[string]
    foreach ($tool in $registry) {
        if (-not $tool.PSObject.Properties['component']) { continue }
        $key = Get-CkComponentKey -Tool $tool
        if ($key -and -not $queuedKeys.ContainsKey($key)) {
            $queuedKeys[$key] = $true
            [void]$queuedIds.Add([string]$tool.id)
        }
    }
    Assert-ModelRepairPage ($queuedIds.Contains('fxap-decryptor')) 'The shared FXAP component must remain in the startup-check queue.'
    Assert-ModelRepairPage (-not $queuedIds.Contains('model-repair')) 'The model repair alias must not enqueue a duplicate startup component check.'

    $quoted = Join-CkArgumentList -Arguments @('fix-models', 'D:\模型 资源\[cars]')
    Assert-ModelRepairPage ($quoted -ceq 'fix-models "D:\模型 资源\[cars]"') 'Model repair command line does not preserve a Chinese path containing spaces and brackets.'

    $source = [IO.File]::ReadAllText((Join-Path $appRoot 'pages\ModelRepairPage.ps1'))
    $fxapSource = [IO.File]::ReadAllText((Join-Path $appRoot 'pages\FxapDecryptorPage.ps1'))
    $dumpSource = [IO.File]::ReadAllText((Join-Path $appRoot 'pages\ServerDumpPage.ps1'))
    $mainSource = [IO.File]::ReadAllText($mainPath)
    $releaseBuilderSource = [IO.File]::ReadAllText((Join-Path $repoRoot 'tools\Build-ReleasePackage.ps1'))
    $releaseWorkflowSource = [IO.File]::ReadAllText((Join-Path $repoRoot '.github\workflows\build-release.yml'))
    Assert-ModelRepairPage ($source.Contains("-Arguments @('fix-models', `$target)")) 'Page does not directly invoke the shared CLI fix-models command.'
    Assert-ModelRepairPage ($source.Contains('不能把整个磁盘作为模型修复目录')) 'Page is missing the drive-root safety guard.'
    Assert-ModelRepairPage ($source.Contains('部分 type 2 VertexBuffer')) 'Page is missing the remote Buffer disclosure.'
    Assert-ModelRepairPage ($source.Contains('$dotnet = Get-CkDotNet8Info')) 'Page must detect the .NET 8 runtime required by the shared FXAP CLI.'
    Assert-ModelRepairPage ($source.Contains('$updateOutputStateAction = (Get-Command Update-CkModelRepairOutputState).ScriptBlock.GetNewClosure()')) 'Page must capture the output parser for asynchronous callbacks.'
    Assert-ModelRepairPage ($source.Contains('$resolveResultAction = (Get-Command Resolve-CkModelRepairResult).ScriptBlock.GetNewClosure()')) 'Page must capture the result resolver for asynchronous callbacks.'
    Assert-ModelRepairPage ($source.Contains('$outputEvent = & $updateOutputStateAction -State $state -Line $Line')) 'Page UI must invoke the captured behavior-tested output parser.'
    Assert-ModelRepairPage ($source.Contains('$callbackResolveResult = $resolveResultAction')) 'Exit callback must retain the captured result resolver.'
    Assert-ModelRepairPage ($source.Contains('$result = & $callbackResolveResult')) 'Exit callback must invoke the captured result resolver instead of relying on caller scope.'
    Assert-ModelRepairPage ($source.Contains('$reportStatus = [string]$result.Status')) 'Page report status must use the behavior-tested result classification.'
    Assert-ModelRepairPage ($source.Contains('$callbackUi.ResultStatus.Text = [string]$result.ResultText')) 'Page UI status must use the same result classification as the report.'

    Assert-ModelRepairPage ($mainSource.Contains('$componentState.Remote[$componentKey]')) 'Remote component state must be keyed by shared component identity.'
    Assert-ModelRepairPage ($mainSource.Contains('$componentState.Checked[$componentKey]')) 'Checked component state must be keyed by shared component identity.'
    Assert-ModelRepairPage ($mainSource.Contains('$queuedComponents.ContainsKey($componentKey)')) 'Startup component checks must deduplicate shared component identities.'
    Assert-ModelRepairPage ($mainSource.Contains('ComponentKey = $componentKey')) 'Active component operations must retain their shared component identity.'
    Assert-ModelRepairPage ($mainSource.Contains('$activateToolIds += $currentToolId')) 'Installing a shared component must refresh the currently visible alias page.'

    Assert-ModelRepairPage ($fxapSource.Contains('$dotnetRequired = [bool]$ui.VertexFixBox.IsChecked')) 'FXAP page must require .NET 8 only when model repair is selected.'
    Assert-ModelRepairPage ($fxapSource.Contains('$state.Ready = $nodeOk -and $componentOk -and ($dotnetOk -or -not $dotnetRequired)')) 'FXAP readiness must include the conditional .NET 8 requirement.'
    Assert-ModelRepairPage ($fxapSource.Contains('$ui.VertexFixBox.Add_Checked($vertexFixChangedHandler)')) 'FXAP page must refresh environment state when model repair is toggled.'
    Assert-ModelRepairPage ($fxapSource.Contains("if (`$vertexFixRequested -and -not (Get-CkDotNet8Info).Ok)")) 'FXAP page must recheck .NET 8 immediately before starting model repair.'
    Assert-ModelRepairPage ($fxapSource.Contains('Register-CkButtonAction -Button $ui.DotNet8DownloadButton')) 'FXAP .NET 8 download button must be wired.'
    Assert-ModelRepairPage (-not $fxapSource.Contains('自包含 EXE / DLL')) 'FXAP page must not claim the framework-dependent repair CLI is self-contained.'

    Assert-ModelRepairPage ($dumpSource.Contains('$dotnetRequired = [bool]$ui.VertexFixBox.IsChecked')) 'Server Dump page must require .NET 8 only when model repair is selected.'
    Assert-ModelRepairPage ($dumpSource.Contains('-and ($dotnetOk -or -not $dotnetRequired)')) 'Server Dump readiness must include the conditional .NET 8 requirement.'
    Assert-ModelRepairPage ($dumpSource.Contains('$ui.VertexFixBox.Add_Checked($vertexFixChangedAction)')) 'Server Dump page must refresh environment state when model repair is toggled.'
    Assert-ModelRepairPage ($dumpSource.Contains("if (`$vertexFixRequested -and -not (Get-CkDotNet8Info).Ok)")) 'Server Dump page must recheck .NET 8 immediately before starting model repair.'
    Assert-ModelRepairPage ($dumpSource.Contains('Register-CkButtonAction -Button $ui.DotNet8DownloadButton')) 'Server Dump .NET 8 download button must be wired.'
    Assert-ModelRepairPage (-not $dumpSource.Contains('自包含 EXE / DLL')) 'Server Dump page must not claim the framework-dependent repair CLI is self-contained.'

    Assert-ModelRepairPage ($releaseBuilderSource.Contains("app\pages\ModelRepairPage.ps1")) 'Release package verification must require ModelRepairPage.ps1.'
    Assert-ModelRepairPage (-not $releaseBuilderSource.Contains('模型修复客户端为自包含 EXE/DLL')) 'Packaged user guide must not claim the repair CLI is self-contained.'
    Assert-ModelRepairPage ($releaseWorkflowSource.Contains('Validate model repair page and callbacks')) 'Release CI must run the model repair callback regression test.'
    Assert-ModelRepairPage ($releaseWorkflowSource.Contains("'app\pages\ModelRepairPage.ps1'")) 'Release CI package verification must require ModelRepairPage.ps1.'

    if (Test-Path -LiteralPath $repairExe -PathType Leaf) {
        $probeRoot = Join-Path $tempRoot '空 模型 [probe]'
        New-Item -ItemType Directory -Path $probeRoot -Force | Out-Null
        $probeOutput = & $repairExe fix-models $probeRoot 2>&1
        Assert-ModelRepairPage ($LASTEXITCODE -eq 0) "Model repair CLI empty-directory probe failed with exit code $LASTEXITCODE."
        Assert-ModelRepairPage (($probeOutput -join [Environment]::NewLine) -match '\[MODEL\]\s+scanned=0,\s*repaired=0,\s*failed=0') 'Model repair CLI probe did not return the expected empty-directory summary.'
    }

    Write-Output "Model repair page regression passed: $assertions assertions."
} finally {
    if (Test-Path -LiteralPath $tempRoot -PathType Container) {
        $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
        $resolvedFixture = [IO.Path]::GetFullPath($tempRoot)
        if (-not $resolvedFixture.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to delete a fixture outside the temporary directory: $resolvedFixture"
        }
        Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
    }
}
