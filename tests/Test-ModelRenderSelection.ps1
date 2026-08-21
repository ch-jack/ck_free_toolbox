[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
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
        & $removeSelectionAction -Path $path
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

Write-Host 'Model render selection and command-line guard tests passed.'
