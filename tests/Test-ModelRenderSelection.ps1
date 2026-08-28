[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName WindowsBase
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Import-Module (Join-Path $repoRoot 'app\modules\ProcessRunner.psm1') -Force
. (Join-Path $repoRoot 'app\pages\ModelRenderPage.ps1')

$rows = @(
    [pscustomobject]@{ Kind = 'vehicle'; Model = 'alpha' },
    [pscustomobject]@{ Kind = 'weapon'; Model = 'beta' },
    [pscustomobject]@{ Kind = 'weapon'; Model = 'gamma' }
)

$allPlan = Get-CkModelSelectionPlan -SelectedRows $rows -AvailableCount $rows.Count
if ($allPlan.UseModelFile -or $allPlan.Models.Count -ne 0) {
    throw '全部选择时仍生成了模型筛选参数。'
}

$partialPlan = Get-CkModelSelectionPlan -SelectedRows @($rows[0], $rows[1], $rows[1]) -AvailableCount ($rows.Count + 1)
if (-not $partialPlan.UseModelFile -or $partialPlan.Models.Count -ne 2) {
    throw '部分选择没有生成去重后的模型清单计划。'
}

$largeModels = @(1..4000 | ForEach-Object { 'model_{0:D5}' -f $_ })
$selectionFile = New-CkModelSelectionFile -Models $largeModels
try {
    $loaded = [IO.File]::ReadAllLines($selectionFile, (New-Object Text.UTF8Encoding($false)))
    if ($loaded.Count -ne $largeModels.Count -or $loaded[0] -cne $largeModels[0] -or $loaded[-1] -cne $largeModels[-1]) {
        throw '模型清单内容不完整。'
    }

    $shortArguments = @('render_all_vehicles.py', 'D:\Car', '--model-file', $selectionFile)
    $shortCommandLine = Join-CkArgumentList -Arguments $shortArguments
    if ($shortCommandLine.Length -ge 1000) {
        throw "模型清单参数仍然异常过长: $($shortCommandLine.Length)"
    }
} finally {
    Remove-CkModelSelectionFile -Path $selectionFile
}
if (Test-Path -LiteralPath $selectionFile -PathType Leaf) {
    throw '模型清单临时文件未被清理。'
}

$lengthError = ''
try {
    Start-CkLoggedProcess -FileName "$env:SystemRoot\System32\cmd.exe" -Arguments @(('x' * 40000)) -WorkingDirectory $repoRoot -Dispatcher ([pscustomobject]@{}) -OnOutput { param($line) } -OnExit { param($code) } | Out-Null
} catch {
    $lengthError = $_.Exception.Message
}
if ($lengthError -notmatch '启动参数过长') {
    throw "共享进程启动器没有返回明确的参数长度错误: $lengthError"
}

$scopedCleanupAction = & {
    . (Join-Path $repoRoot 'app\pages\ModelRenderPage.ps1')
    $newSelectionAction = (Get-Command New-CkModelSelectionFile).ScriptBlock.GetNewClosure()
    $removeSelectionAction = (Get-Command Remove-CkModelSelectionFile).ScriptBlock.GetNewClosure()
    return {
        $path = & $newSelectionAction -Models @('scope_model')
        [void]$removeSelectionAction.Invoke([string]$path)
        return $path
    }.GetNewClosure()
}
$scopedPath = & $scopedCleanupAction
if (Test-Path -LiteralPath $scopedPath -PathType Leaf) {
    throw '页面辅助函数离开脚本作用域后无法通过已捕获回调清理清单。'
}

$pageSource = [IO.File]::ReadAllText((Join-Path $repoRoot 'app\pages\ModelRenderPage.ps1'))
foreach ($actionName in @('getModelSelectionPlanAction', 'newModelSelectionFileAction', 'removeModelSelectionFileAction')) {
    if ($pageSource -notmatch [regex]::Escape("`$$actionName")) {
        throw "模型截图页面未捕获辅助回调: $actionName"
    }
}
foreach ($progressToken in @('^\[scan\]', '^\[jobs\]', '^\[start\]', '^\[ok\]|^\[skip\]', "'等待中'")) {
    if (-not $pageSource.Contains($progressToken)) {
        throw "模型截图页面缺少大批量进度处理: $progressToken"
    }
}

$callbackCounter = [pscustomobject]@{ Value = 0 }
$nestedProgress = {
    param([string]$line)
    $callbackCounter.Value++
}.GetNewClosure()
$nestedOutput = {
    param([string]$line)
    [void]$nestedProgress.Invoke($line)
}.GetNewClosure()
foreach ($index in 1..10000) {
    [void]$nestedOutput.Invoke("[scan] phase=assets scanned=$index candidates=$index")
}
if ($callbackCounter.Value -ne 10000) {
    throw "嵌套日志回调压力测试数量错误: $($callbackCounter.Value)"
}

$runnerSource = [IO.File]::ReadAllText((Join-Path $repoRoot 'app\modules\ProcessRunner.psm1'))
foreach ($invokeToken in @('$callbackProgress.Invoke', '$OnOutput.Invoke', '$OnExit.Invoke', '$OnError.Invoke')) {
    if (-not ($pageSource + $runnerSource).Contains($invokeToken)) {
        throw "日志回调仍缺少 ScriptBlock.Invoke: $invokeToken"
    }
}
foreach ($exitToken in @('[datetime]$callbackStartedAt', 'ModelRender exit step=', '$callbackUi.AssetList.Items', '$callbackSelectedKeys.ContainsKey')) {
    if (-not $pageSource.Contains($exitToken)) {
        throw "模型渲染退出回调缺少空值保护或步骤诊断: $exitToken"
    }
}
if ($pageSource.Contains('& $callbackProgress') -or $pageSource.Contains('& $removeModelSelectionFileAction') -or $runnerSource.Contains('& $OnOutput')) {
    throw '日志回调仍使用易失效的调用运算符。'
}

$processState = [pscustomobject]@{ Lines = 0; Exit = $false; Code = -1; Error = '' }
$processOutput = { param($line); $processState.Lines++ }.GetNewClosure()
$processExit = { param($code); $processState.Code = $code; $processState.Exit = $true }.GetNewClosure()
$processError = { param($message); $processState.Error = $message }.GetNewClosure()
$dispatcher = [Windows.Threading.Dispatcher]::CurrentDispatcher
$childCommand = '1..200 | ForEach-Object { Write-Output (''line-'' + $_) }'
$runtime = Start-CkLoggedProcess `
    -FileName "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -Arguments @('-NoProfile', '-Command', $childCommand) `
    -WorkingDirectory $repoRoot `
    -Dispatcher $dispatcher `
    -OnOutput $processOutput `
    -OnExit $processExit `
    -OnError $processError
$deadline = (Get-Date).AddSeconds(20)
while (-not $processState.Exit -and (Get-Date) -lt $deadline) {
    $frame = New-Object Windows.Threading.DispatcherFrame
    $stopFrame = [Action]{ $frame.Continue = $false }.GetNewClosure()
    [void]$dispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::Background, $stopFrame)
    [Windows.Threading.Dispatcher]::PushFrame($frame)
    Start-Sleep -Milliseconds 10
}
if (-not $processState.Exit) { throw '共享进程回调测试等待超时。' }
if ($processState.Code -ne 0 -or $processState.Lines -ne 200 -or $processState.Error) {
    throw "共享进程回调测试失败: code=$($processState.Code) lines=$($processState.Lines) error=$($processState.Error)"
}

Write-Host 'Model render selection and command-line guard tests passed.'
