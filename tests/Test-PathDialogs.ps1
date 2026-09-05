# Run with Windows PowerShell 5.1: powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File tests\Test-PathDialogs.ps1
# These tests never display a window or start a component task.
#requires -Version 5.1
$ErrorActionPreference = 'Stop'

if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne [Threading.ApartmentState]::STA) {
    throw 'Run this test with powershell.exe -STA.'
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

$repoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $repoRoot 'app\modules\UiKit.psm1') -Force

$script:assertionCount = 0
function Assert-CkPathDialog {
    param([bool]$Condition, [string]$Message)
    $script:assertionCount++
    if (-not $Condition) { throw $Message }
}

function Assert-CkPathEquals {
    param([AllowNull()][string]$Actual, [AllowNull()][string]$Expected, [string]$Message)
    Assert-CkPathDialog ([string]::Equals($Actual.TrimEnd('\'), $Expected.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)) "$Message. Expected '$Expected'; actual '$Actual'."
}

function Get-CkPagePickerAction {
    param([string]$Page, [string]$Variable)
    $pagePath = Join-Path $repoRoot ('app\pages\' + $Page)
    $parseErrors = $null
    $tokens = $null
    $pageAst = [Management.Automation.Language.Parser]::ParseFile($pagePath, [ref]$tokens, [ref]$parseErrors)
    Assert-CkPathDialog ($parseErrors.Count -eq 0) "Parse errors in $Page."
    $assignment = $pageAst.Find({
        param($node)
        $node -is [Management.Automation.Language.AssignmentStatementAst] -and
        $node.Left -is [Management.Automation.Language.VariableExpressionAst] -and
        $node.Left.VariablePath.UserPath -eq $Variable
    }, $true)
    Assert-CkPathDialog ($null -ne $assignment) "Missing picker action $Page / $Variable."
    $body = $assignment.Right.Find({ param($node) $node -is [Management.Automation.Language.ScriptBlockExpressionAst] }, $true).ScriptBlock
    Assert-CkPathDialog ($null -ne $body) "Missing picker script block $Page / $Variable."
    $source = $body.Extent.Text
    return [scriptblock]::Create($source.Substring(1, $source.Length - 2))
}

function Invoke-CkPagePickerTest {
    param(
        [scriptblock]$Action,
        [string]$Label,
        [AllowNull()][string]$InputPath,
        [string]$Selection,
        [string]$ExpectedDirectory,
        [bool]$Accepted,
        [ValidateSet('Input', 'Target', 'Report', 'OpenArgument', 'SaveArgument', 'Folder', 'ImageFolder')][string]$Mode = 'Input'
    )

    $textBox = [pscustomobject]@{ Text = [string]$InputPath }
    $ui = [pscustomobject]@{ InputBox = $textBox; TargetBox = $textBox; OutputBox = $textBox }
    if ($Mode -eq 'ImageFolder') {
        $customOutput = Join-Path $Selection 'custom output'
        $ui.OutputBox = [pscustomobject]@{ Text = $customOutput }
        $chooseFolderAction = Get-CkPagePickerAction -Page 'ImageCompressorPage.ps1' -Variable 'chooseFolderAction'
    }
    $state = [pscustomobject]@{ TargetPath = [string]$InputPath; ReportRoot = [string]$InputPath }
    $root = Microsoft.PowerShell.Utility\New-Object System.Windows.Controls.Grid
    $trace = [pscustomobject]@{ Dialog = $null; ParsedReport = $null }

    # Override only construction in this invocation scope. The actual helper receives
    # a real dialog, with ShowDialog replaced so no native UI can be displayed.
    function New-Object {
        param([Parameter(Position = 0)][string]$TypeName)
        if ($TypeName -notin @('System.Windows.Forms.OpenFileDialog', 'System.Windows.Forms.FolderBrowserDialog', 'Microsoft.Win32.OpenFileDialog', 'Microsoft.Win32.SaveFileDialog')) {
            throw "Unexpected New-Object in picker test: $TypeName"
        }
        $dialog = Microsoft.PowerShell.Utility\New-Object -TypeName $TypeName
        $dialog | Add-Member -NotePropertyMembers @{
            CkTestAccepted = $Accepted
            CkTestSelection = $Selection
            CkTestShowCount = 0
            CkTestDisposed = $false
            CkTestInitialDirectory = ''
        }
        $dialog | Add-Member -MemberType ScriptMethod -Name ShowDialog -Force -Value {
            $this.CkTestShowCount++
            if ($this -is [System.Windows.Forms.FolderBrowserDialog]) {
                $this.CkTestInitialDirectory = $this.SelectedPath
                if ($this.CkTestAccepted) { $this.SelectedPath = $this.CkTestSelection }
            } else {
                $this.CkTestInitialDirectory = $this.InitialDirectory
                if ($this.CkTestAccepted) { $this.FileName = $this.CkTestSelection }
            }
            if ($this -is [System.Windows.Forms.CommonDialog]) {
                if ($this.CkTestAccepted) { return [System.Windows.Forms.DialogResult]::OK }
                return [System.Windows.Forms.DialogResult]::Cancel
            }
            return [bool]$this.CkTestAccepted
        }
        if ($dialog -is [System.Windows.Forms.CommonDialog]) {
            $dialog | Add-Member -MemberType ScriptMethod -Name Dispose -Force -Value { $this.CkTestDisposed = $true }
        }
        $trace.Dialog = $dialog
        return $dialog
    }

    # Stop the report action immediately after it hands the selected path to the
    # report reader; the following confirmation/download belongs to another test.
    $getRetryReportInfoAction = {
        param([string]$Path)
        $trace.ParsedReport = $Path
        throw 'CK_TEST_REPORT_PARSED'
    }

    try {
        try {
            if ($Mode -eq 'OpenArgument') { & $Action $textBox 'All files|*.*' 'Test open' }
            elseif ($Mode -eq 'SaveArgument') { & $Action $textBox 'JSON files|*.json' 'Test save' '.json' }
            else { & $Action }
        } catch {
            if ($Mode -ne 'Report' -or $_.Exception.Message -ne 'CK_TEST_REPORT_PARSED') { throw }
        }
        Assert-CkPathDialog ($null -ne $trace.Dialog) "$Label did not construct a dialog."
        Assert-CkPathDialog ($trace.Dialog.CkTestShowCount -eq 1) "$Label did not reach ShowDialog exactly once."
        Assert-CkPathEquals $trace.Dialog.CkTestInitialDirectory $ExpectedDirectory "$Label initial directory"
        if ($Mode -eq 'Report') {
            if ($Accepted) { Assert-CkPathEquals $trace.ParsedReport $Selection "$Label selected report" }
            else { Assert-CkPathDialog ($null -eq $trace.ParsedReport) "$Label read a report after cancellation." }
        } else {
            $expectedText = if ($Accepted) { $Selection } else { [string]$InputPath }
            Assert-CkPathDialog ($textBox.Text -ceq $expectedText) "$Label changed the input incorrectly (accepted=$Accepted)."
            if ($Mode -eq 'Target') {
                Assert-CkPathDialog ($state.TargetPath -ceq $expectedText) "$Label did not preserve/update TargetPath with the input."
            }
        }
        if ($Mode -eq 'ImageFolder') {
            $expectedOutput = if ($Accepted) { $Selection.TrimEnd('\') + '_compressed' } else { $customOutput }
            Assert-CkPathDialog ($ui.OutputBox.Text -ceq $expectedOutput) "$Label overwrote the custom output on cancellation or did not update it on acceptance."
        }
        if ($trace.Dialog -is [System.Windows.Forms.CommonDialog]) {
            Assert-CkPathDialog $trace.Dialog.CkTestDisposed "$Label did not dispose its dialog."
        }
    } finally {
        if ($trace.Dialog -is [System.Windows.Forms.CommonDialog]) { $trace.Dialog.PSBase.Dispose() }
    }
}

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('ck-path-dialogs-' + [Guid]::NewGuid().ToString('N'))
$fixtureDirectory = Join-Path $tempRoot '中文 资源 [literal]'
$existingFile = Join-Path $fixtureDirectory '车辆 [01].rpf'
$relativeFile = '车辆 [01].rpf'
$missingPath = Join-Path $fixtureDirectory 'missing\nested\new plan.json'
$originalLocation = Get-Location

try {
    [void][IO.Directory]::CreateDirectory($fixtureDirectory)
    [IO.File]::WriteAllText($existingFile, 'fixture')
    Set-Location -LiteralPath $fixtureDirectory
    $beforeEntries = @([IO.Directory]::GetFileSystemEntries($tempRoot, '*', [IO.SearchOption]::AllDirectories) | Sort-Object)

    $dialogTypes = @(
        'System.Windows.Forms.OpenFileDialog',
        'System.Windows.Forms.FolderBrowserDialog',
        'Microsoft.Win32.OpenFileDialog',
        'Microsoft.Win32.SaveFileDialog'
    )
    $helperCases = @(
        @{ Name = 'null'; Path = $null; Directory = ''; File = '' },
        @{ Name = 'empty'; Path = ''; Directory = ''; File = '' },
        @{ Name = 'whitespace'; Path = " `t`r`n "; Directory = ''; File = '' },
        @{ Name = 'invalid NUL'; Path = ('bad' + [char]0 + 'path'); Directory = ''; File = '' },
        @{ Name = 'invalid character'; Path = 'bad<name>.json'; Directory = ''; File = '' },
        @{ Name = 'invalid wildcard'; Path = 'bad?name.json'; Directory = ''; File = '' },
        @{ Name = 'unmatched quote'; Path = '"bad'; Directory = ''; File = '' },
        @{ Name = 'existing directory'; Path = $fixtureDirectory; Directory = $fixtureDirectory; File = '' },
        @{ Name = 'existing file'; Path = $existingFile; Directory = $fixtureDirectory; File = $existingFile },
        @{ Name = 'relative existing file'; Path = $relativeFile; Directory = $fixtureDirectory; File = $existingFile },
        @{ Name = 'relative current directory'; Path = '.'; Directory = $fixtureDirectory; File = '' },
        @{ Name = 'quoted file'; Path = ('  "' + $existingFile + '"  '); Directory = $fixtureDirectory; File = $existingFile },
        @{ Name = 'quoted directory'; Path = ('"' + $fixtureDirectory + '"'); Directory = $fixtureDirectory; File = '' },
        @{ Name = 'missing nested path'; Path = $missingPath; Directory = $fixtureDirectory; File = '' },
        @{ Name = 'relative missing filename'; Path = 'new plan.json'; Directory = $fixtureDirectory; File = '' }
    )

    foreach ($typeName in $dialogTypes) {
        foreach ($case in $helperCases) {
            $dialog = New-Object -TypeName $typeName
            try {
                Set-CkDialogInitialPath -Dialog $dialog -Path $case.Path
                $label = "$typeName / $($case.Name)"
                if ($dialog -is [System.Windows.Forms.FolderBrowserDialog]) {
                    Assert-CkPathEquals $dialog.SelectedPath $case.Directory $label
                } else {
                    Assert-CkPathEquals $dialog.InitialDirectory $case.Directory "$label directory"
                    Assert-CkPathEquals $dialog.FileName $case.File "$label filename"
                }
            } finally {
                if ($dialog -is [IDisposable]) { $dialog.Dispose() }
            }
        }
        foreach ($invalidPath in @($null, '', ' ', ('bad' + [char]0))) {
            $dialog = New-Object -TypeName $typeName
            try {
                if ($dialog -is [System.Windows.Forms.FolderBrowserDialog]) { $dialog.SelectedPath = $fixtureDirectory }
                else { $dialog.InitialDirectory = $fixtureDirectory; $dialog.FileName = $existingFile }
                Set-CkDialogInitialPath -Dialog $dialog -Path $invalidPath
                if ($dialog -is [System.Windows.Forms.FolderBrowserDialog]) {
                    Assert-CkPathEquals $dialog.SelectedPath $fixtureDirectory "$typeName invalid input preserves configured directory"
                } else {
                    Assert-CkPathEquals $dialog.InitialDirectory $fixtureDirectory "$typeName invalid input preserves configured directory"
                    Assert-CkPathEquals $dialog.FileName $existingFile "$typeName invalid input preserves configured filename"
                }
            } finally {
                if ($dialog -is [IDisposable]) { $dialog.Dispose() }
            }
        }
    }

    foreach ($savePath in @('new plan.json', $missingPath, ('"' + $missingPath + '"'))) {
        $dialog = New-Object Microsoft.Win32.SaveFileDialog
        Set-CkDialogInitialPath -Dialog $dialog -Path $savePath -ForSave
        Assert-CkPathEquals $dialog.InitialDirectory $fixtureDirectory 'Save uses the nearest existing directory'
        Assert-CkPathEquals $dialog.FileName 'new plan.json' 'Save preserves a new basename'
    }
    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    Set-CkDialogInitialPath -Dialog $dialog -Path $existingFile -ForSave
    Assert-CkPathEquals $dialog.InitialDirectory $fixtureDirectory 'Save existing file directory'
    Assert-CkPathEquals $dialog.FileName $existingFile 'Save existing file full name'

    $pageActions = @(
        @{ Page = 'RpfToFivemPage.ps1'; Variable = 'chooseFileAction'; Mode = 'Input' },
        @{ Page = 'RpfToFivemPage.ps1'; Variable = 'chooseFolderAction'; Mode = 'Folder' },
        @{ Page = 'RpfToFivemPage.ps1'; Variable = 'chooseOutputAction'; Mode = 'Folder' },
        @{ Page = 'AntiJohnPage.ps1'; Variable = 'chooseZipAction'; Mode = 'Target' },
        @{ Page = 'ServerDumpPage.ps1'; Variable = 'retryFailedAction'; Mode = 'Report' },
        @{ Page = 'ClothingRepackerPage.ps1'; Variable = 'chooseOpenFileAction'; Mode = 'OpenArgument' },
        @{ Page = 'ClothingRepackerPage.ps1'; Variable = 'chooseSaveFileAction'; Mode = 'SaveArgument' },
        @{ Page = 'ImageCompressorPage.ps1'; Variable = 'chooseInputFolderAction'; Mode = 'ImageFolder' }
    )
    $pickerCases = @(
        @{ Name = 'null'; Path = $null; Directory = '' },
        @{ Name = 'empty'; Path = ''; Directory = '' },
        @{ Name = 'invalid path'; Path = ('bad' + [char]0); Directory = '' },
        @{ Name = 'whitespace'; Path = '   '; Directory = '' },
        @{ Name = 'relative missing filename'; Path = 'new plan.json'; Directory = $fixtureDirectory },
        @{ Name = 'literal relative file'; Path = $relativeFile; Directory = $fixtureDirectory },
        @{ Name = 'missing nested output'; Path = $missingPath; Directory = $fixtureDirectory }
    )
    foreach ($spec in $pageActions) {
        $action = Get-CkPagePickerAction -Page $spec.Page -Variable $spec.Variable
        foreach ($case in $pickerCases) {
            foreach ($accepted in @($false, $true)) {
                $selection = if ($spec.Mode -in @('Folder', 'ImageFolder')) { $fixtureDirectory } else { $existingFile }
                Invoke-CkPagePickerTest -Action $action -Label "$($spec.Page) / $($spec.Variable) / $($case.Name) / accepted=$accepted" -InputPath $case.Path -Selection $selection -ExpectedDirectory $case.Directory -Accepted $accepted -Mode $spec.Mode
            }
        }
    }

    $afterEntries = @([IO.Directory]::GetFileSystemEntries($tempRoot, '*', [IO.SearchOption]::AllDirectories) | Sort-Object)
    Assert-CkPathDialog (($beforeEntries -join "`n") -ceq ($afterEntries -join "`n")) 'Path initialization created files or directories.'
    Assert-CkPathDialog ([IO.File]::ReadAllText($existingFile) -ceq 'fixture') 'Path initialization changed an existing file.'
    Write-Output "Path dialog regression passed: $script:assertionCount assertions; four real dialog types and eight page actions; no windows displayed."
} finally {
    Set-Location -LiteralPath $originalLocation.Path
    # Delete only this unique fixture beneath the verified temporary directory.
    $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    $resolvedFixture = [IO.Path]::GetFullPath($tempRoot)
    if (-not $resolvedFixture.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to delete a fixture outside the temporary directory: $resolvedFixture"
    }
    if (Test-Path -LiteralPath $resolvedFixture) { Remove-Item -LiteralPath $resolvedFixture -Recurse -Force }
}