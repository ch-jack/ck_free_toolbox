function New-CkEnhancedConverterPage {
    param([Parameter(Mandatory)]$Context)

    function ConvertFrom-CkHexText {
        param([Parameter(Mandatory)][string]$Hex)
        $chars = New-Object System.Collections.Generic.List[char]
        foreach ($part in ($Hex -split ' ')) {
            if ([string]::IsNullOrWhiteSpace($part)) { continue }
            $chars.Add([char][Convert]::ToInt32($part, 16))
        }
        return -join $chars
    }

    function T { param([string]$Hex) ConvertFrom-CkHexText $Hex }

    $text = [pscustomobject]@{
        Title = T '589E 5F3A 7248 8F6C 6362 5668'
        Subtitle = T '4F7F 7528 0020 0046 0069 0076 0065 004D 0020 5B98 65B9 0020 0041 006C 0063 0068 0065 006D 0069 0073 0074 0020 0043 004C 0049 0020 6279 91CF 8F6C 6362 6216 7CBE 70BC 8D44 6E90'
        Checking = T '68C0 6D4B 4E2D'
        Ready = T '0041 006C 0063 0068 0065 006D 0069 0073 0074 0020 0043 004C 0049 0020 5DF2 5C31 7EEA'
        Missing = T '7F3A 5C11 0020 0041 006C 0063 0068 0065 006D 0069 0073 0074 0043 006C 0069 002E 0065 0078 0065'
        InputLabel = T '8F93 5165 8DEF 5F84'
        OutputLabel = T '8F93 51FA 76EE 5F55'
        ChooseFile = T '9009 62E9 6587 4EF6'
        ChooseFolder = T '9009 62E9 76EE 5F55'
        OpenOutput = T '6253 5F00 8F93 51FA'
        Params = T '8F6C 6362 53C2 6570'
        FailOnError = T '9047 5230 9996 4E2A 9519 8BEF 5373 505C 6B62'
        Refine = T '7CBE 70BC 8D44 6E90'
        Relaxed = T '5BBD 677E 6A21 5F0F'
        Threads = T '7EBF 7A0B 6570 0028 002D 006A 004E 0029'
        Overwrite = T '8986 76D6 73B0 6709 6587 4EF6 0028 002D 0066 0029'
        Telemetry = T '5DF2 968F 9644 0020 0061 006C 0063 0068 0065 006D 0069 0073 0074 002D 0063 006F 006E 0066 0069 0067 002E 0074 0078 0074 0020 542F 7528 5B98 65B9 9065 6D4B 3002'
        Start = T '5F00 59CB 8F6C 6362'
        Stop = T '505C 6B62 4EFB 52A1'
        Waiting = T '7B49 5F85 4EFB 52A1'
        Running = T '6B63 5728 8FD0 884C'
        Stopped = T '5DF2 505C 6B62'
        Done = T '8F6C 6362 5B8C 6210'
        Failed = T '8F6C 6362 5931 8D25'
        ProgressTitle = T '8F6C 6362 8FDB 5EA6'
        StatusIdle = T '9009 62E9 8F93 5165 548C 8F93 51FA 540E 5F00 59CB 4EFB 52A1 3002'
        Logs = T '4EFB 52A1 65E5 5FD7'
        LogWaiting = T '7B49 5F85 4EFB 52A1 8F93 51FA 002E 002E 002E'
        Command = T '547D 4EE4 9884 89C8'
        InputMissing = T '8BF7 9009 62E9 5B58 5728 7684 8F93 5165 6587 4EF6 6216 76EE 5F55 3002'
        OutputMissing = T '8BF7 9009 62E9 8F93 51FA 76EE 5F55 3002'
        InvalidThreads = T '7EBF 7A0B 6570 5FC5 987B 662F 0020 0031 002D 0031 0032 0038 0020 4E4B 95F4 7684 6574 6570 3002'
        CliMissing = T '627E 4E0D 5230 0020 0041 006C 0063 0068 0065 006D 0069 0073 0074 0043 006C 0069 002E 0065 0078 0065 3002'
        Starting = T '5F00 59CB 8F6C 6362 002E 002E 002E'
        NoOutput = T '8FDB 7A0B 6CA1 6709 8F93 51FA 65E5 5FD7 3002'
        ExitCode = T '8FDB 7A0B 9000 51FA 7801'
        BrowseInputFile = T '9009 62E9 9700 8981 8F6C 6362 7684 8F93 5165 6587 4EF6'
        BrowseInputFolder = T '9009 62E9 9700 8981 8F6C 6362 7684 8F93 5165 76EE 5F55'
        BrowseOutput = T '9009 62E9 8F93 51FA 76EE 5F55'
    }

    $state = [pscustomobject]@{
        Process = $null
        CancelRequested = $false
        CliPath = Join-Path $Context.Paths.AppRoot 'tools\alchemist\AlchemistCli.exe'
        ToolRoot = Join-Path $Context.Paths.AppRoot 'tools\alchemist'
    }

    $xaml = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
              xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
              VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
  <ScrollViewer.Resources>
    <Style TargetType="CheckBox"><Setter Property="Foreground" Value="#A4AAB4"/><Setter Property="FontSize" Value="13"/><Setter Property="VerticalAlignment" Value="Center"/></Style>
  </ScrollViewer.Resources>
  <StackPanel Margin="22">
    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="18" Margin="0,0,0,14">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <StackPanel>
          <StackPanel Orientation="Horizontal"><Border Width="4" Height="22" CornerRadius="3" Background="#9B7BFF" Margin="0,0,10,0"/><TextBlock Text="$($text.Title)" FontSize="22" FontWeight="Bold"/></StackPanel>
          <TextBlock Text="$($text.Subtitle)" Foreground="#777B83" FontSize="13" Margin="14,6,0,0"/>
        </StackPanel>
        <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center"><Ellipse x:Name="EnvironmentDot" Width="10" Height="10" Fill="#31D69A" Margin="0,0,8,0"/><TextBlock x:Name="EnvironmentText" Text="$($text.Checking)" Foreground="#31D69A" FontWeight="SemiBold"/></StackPanel>
      </Grid>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="$($text.InputLabel)" Foreground="#B8C0CC" FontSize="13" Margin="0,0,0,6"/>
        <Grid Margin="0,0,0,12"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><TextBox x:Name="InputBox" Height="38"/><Button x:Name="ChooseInputFileButton" Grid.Column="1" Content="$($text.ChooseFile)" Height="38" Margin="8,0,0,0" Background="#173055" Foreground="#58A6FF"/><Button x:Name="ChooseInputFolderButton" Grid.Column="2" Content="$($text.ChooseFolder)" Height="38" Margin="8,0,0,0"/></Grid>
        <TextBlock Text="$($text.OutputLabel)" Foreground="#B8C0CC" FontSize="13" Margin="0,0,0,6"/>
        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><TextBox x:Name="OutputBox" Height="38"/><Button x:Name="ChooseOutputButton" Grid.Column="1" Content="$($text.ChooseFolder)" Height="38" Margin="8,0,0,0" Background="#173055" Foreground="#58A6FF"/><Button x:Name="OpenOutputButton" Grid.Column="2" Content="$($text.OpenOutput)" Height="38" Margin="8,0,0,0"/></Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="$($text.Params)" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions><CheckBox x:Name="FailOnErrorBox" Content="$($text.FailOnError)" ToolTip="--fail-on-error"/><CheckBox x:Name="RefineBox" Grid.Column="1" Content="$($text.Refine)" ToolTip="--refine"/><CheckBox x:Name="RelaxedBox" Grid.Column="2" Content="$($text.Relaxed)" ToolTip="--relaxed"/><StackPanel Grid.Column="3"><TextBlock Text="$($text.Threads)" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="ThreadsBox" Height="34" Text="12"/></StackPanel></Grid>
        <CheckBox x:Name="OverwriteBox" Content="$($text.Overwrite)" IsChecked="True" Margin="0,14,0,0" ToolTip="-f"/>
        <TextBlock Text="$($text.Telemetry)" Foreground="#6E7580" FontSize="12" Margin="0,10,0,0"/>
      </StackPanel>
    </Border>

    <Grid Margin="0,0,0,14"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="140"/></Grid.ColumnDefinitions><Button x:Name="StartButton" Content="$($text.Start)" Height="46" FontWeight="Bold" Background="#173055" Foreground="#58A6FF"/><Button x:Name="StopButton" Grid.Column="1" Content="$($text.Stop)" Height="46" Margin="8,0,0,0" Foreground="#F28B94" IsEnabled="False"/></Grid>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,10"><TextBlock Text="$($text.ProgressTitle)" FontSize="18" FontWeight="Bold"/><StackPanel Orientation="Horizontal" HorizontalAlignment="Right"><TextBlock x:Name="ProgressText" Text="0%" Foreground="#58A6FF" FontWeight="Bold"/><TextBlock Text="  ·  "/><TextBlock x:Name="ResultStatus" Text="$($text.Waiting)" Foreground="#777B83"/></StackPanel></Grid>
        <ProgressBar x:Name="ProgressBar" Height="10" Minimum="0" Maximum="100" Value="0"/>
        <TextBlock x:Name="StatusLine" Text="$($text.StatusIdle)" Foreground="#8B9099" FontSize="13" Margin="0,10,0,0"/>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14"><StackPanel><TextBlock Text="$($text.Command)" FontSize="18" FontWeight="Bold" Margin="0,0,0,9"/><TextBox x:Name="CommandBox" MinHeight="46" TextWrapping="Wrap" FontFamily="Consolas" FontSize="12" IsReadOnly="True"/></StackPanel></Border>
    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16"><StackPanel><TextBlock Text="$($text.Logs)" FontSize="18" FontWeight="Bold" Margin="0,0,0,9"/><TextBox x:Name="LogBox" MinHeight="210" MaxHeight="430" AcceptsReturn="True" TextWrapping="NoWrap" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" IsReadOnly="True" Text="$($text.LogWaiting)"/></StackPanel></Border>
  </StackPanel>
</ScrollViewer>
"@

    $root = Import-CkXaml $xaml
    $ui = Get-CkNamedControls -Root $root -Names @('EnvironmentDot','EnvironmentText','InputBox','ChooseInputFileButton','ChooseInputFolderButton','OutputBox','ChooseOutputButton','OpenOutputButton','FailOnErrorBox','RefineBox','RelaxedBox','ThreadsBox','OverwriteBox','StartButton','StopButton','ResultStatus','ProgressBar','ProgressText','StatusLine','CommandBox','LogBox')
    $ui.OutputBox.Text = Join-Path ([Environment]::GetFolderPath('Desktop')) 'AlchemistOutput'

    function Update-EnhancedEnvironment {
        $ok = Test-Path -LiteralPath $state.CliPath -PathType Leaf
        Set-CkStatusDot $ui.EnvironmentDot $ok
        $ui.EnvironmentText.Foreground = if ($ok) { '#31D69A' } else { '#EF6B73' }
        $ui.EnvironmentText.Text = if ($ok) { $text.Ready } else { $text.Missing }
        $ui.EnvironmentText.ToolTip = $state.CliPath
    }

    function Set-EnhancedRunning {
        param([bool]$Running)
        foreach ($control in @($ui.InputBox,$ui.ChooseInputFileButton,$ui.ChooseInputFolderButton,$ui.OutputBox,$ui.ChooseOutputButton,$ui.FailOnErrorBox,$ui.RefineBox,$ui.RelaxedBox,$ui.ThreadsBox,$ui.OverwriteBox,$ui.StartButton)) { $control.IsEnabled = -not $Running }
        $ui.StopButton.IsEnabled = $Running
        if ($Running) {
            $ui.ProgressBar.IsIndeterminate = $true
            $ui.ProgressBar.Value = 0
            $ui.ProgressText.Text = $text.Running
            $ui.ResultStatus.Text = $text.Running
            $ui.ResultStatus.Foreground = '#58A6FF'
            $ui.StatusLine.Text = $text.Starting
        } else {
            $ui.ProgressBar.IsIndeterminate = $false
        }
    }

    function Get-EnhancedArguments {
        $inputPath = $ui.InputBox.Text.Trim()
        $outputPath = $ui.OutputBox.Text.Trim()
        if (-not (Test-Path -LiteralPath $state.CliPath -PathType Leaf)) { throw $text.CliMissing }
        if ([string]::IsNullOrWhiteSpace($inputPath) -or -not (Test-Path -LiteralPath $inputPath)) { throw $text.InputMissing }
        if ([string]::IsNullOrWhiteSpace($outputPath)) { throw $text.OutputMissing }
        $threads = 12
        if (-not [int]::TryParse($ui.ThreadsBox.Text.Trim(), [ref]$threads) -or $threads -lt 1 -or $threads -gt 128) { throw $text.InvalidThreads }
        $args = New-Object System.Collections.Generic.List[object]
        if ($ui.FailOnErrorBox.IsChecked) { $args.Add('--fail-on-error') }
        if ($ui.RefineBox.IsChecked) { $args.Add('--refine') }
        if ($ui.RelaxedBox.IsChecked) { $args.Add('--relaxed') }
        if ($ui.OverwriteBox.IsChecked) { $args.Add('-f') }
        $args.Add(('-j{0}' -f $threads))
        $args.Add($inputPath)
        $args.Add($outputPath)
        return ,$args.ToArray()
    }

    function Update-EnhancedCommandPreview {
        try { $ui.CommandBox.Text = 'AlchemistCli.exe ' + (Join-CkArgumentList -Arguments (Get-EnhancedArguments)) } catch { $ui.CommandBox.Text = $_.Exception.Message }
    }

    $chooseInputFileAction = { $dialog = New-Object System.Windows.Forms.OpenFileDialog; $dialog.Title = $text.BrowseInputFile; $dialog.Filter = 'All files (*.*)|*.*'; if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $ui.InputBox.Text = $dialog.FileName; & $updatePreviewAction } }.GetNewClosure()
    $chooseInputFolderAction = { $dialog = New-Object System.Windows.Forms.FolderBrowserDialog; $dialog.Description = $text.BrowseInputFolder; $dialog.ShowNewFolderButton = $false; if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $ui.InputBox.Text = $dialog.SelectedPath; & $updatePreviewAction } }.GetNewClosure()
    $chooseOutputAction = { $dialog = New-Object System.Windows.Forms.FolderBrowserDialog; $dialog.Description = $text.BrowseOutput; $dialog.SelectedPath = $ui.OutputBox.Text.Trim(); $dialog.ShowNewFolderButton = $true; if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $ui.OutputBox.Text = $dialog.SelectedPath; & $updatePreviewAction } }.GetNewClosure()
    $openOutputAction = { $path = $ui.OutputBox.Text.Trim(); if (-not (Test-Path -LiteralPath $path -PathType Container)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }; Start-Process -FilePath explorer.exe -ArgumentList @($path) }.GetNewClosure()

    $showPageError = { param($message) $ui.ResultStatus.Text = $text.Failed; $ui.ResultStatus.Foreground = '#EF7C86'; $ui.StatusLine.Text = $message; Add-CkLogLine -TextBox $ui.LogBox -Line "[toolbox] $message"; [System.Windows.MessageBox]::Show($message, "CKFreeToolbox - $($text.Title)") | Out-Null }.GetNewClosure()

    function Start-EnhancedConversion {
        $args = Get-EnhancedArguments
        $outputPath = $ui.OutputBox.Text.Trim()
        New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
        $state.CancelRequested = $false
        $ui.LogBox.Text = "$($text.Starting)`r`nInput: $($ui.InputBox.Text.Trim())`r`nOutput: $outputPath`r`nCommand: AlchemistCli.exe $(Join-CkArgumentList -Arguments $args)"
        & $setRunningAction $true

        $callbackUi = $ui
        $callbackText = $text
        $callbackState = $state
        $onOutput = {
            param($line)
            Add-CkLogLine -TextBox $callbackUi.LogBox -Line $line
            if ($line -match '(?<!\d)(?<percent>100|[1-9]?\d)(?:\.\d+)?\s*%') {
                $percent = [Math]::Max(0, [Math]::Min(100, [double]$Matches.percent))
                $callbackUi.ProgressBar.IsIndeterminate = $false
                $callbackUi.ProgressBar.Value = $percent
                $callbackUi.ProgressText.Text = ('{0:0}%' -f $percent)
            }
        }.GetNewClosure()
        $onExit = {
            param($exitCode)
            & $setRunningAction $false
            if ($callbackState.CancelRequested) {
                $callbackUi.ProgressBar.Value = 0
                $callbackUi.ProgressText.Text = $callbackText.Stopped
                $callbackUi.ResultStatus.Text = $callbackText.Stopped
                $callbackUi.ResultStatus.Foreground = '#F4B860'
                $callbackUi.StatusLine.Text = $callbackText.Stopped
            } elseif ($exitCode -eq 0) {
                $callbackUi.ProgressBar.Value = 100
                $callbackUi.ProgressText.Text = '100%'
                $callbackUi.ResultStatus.Text = $callbackText.Done
                $callbackUi.ResultStatus.Foreground = '#31D69A'
                $callbackUi.StatusLine.Text = $callbackText.Done
            } else {
                $callbackUi.ProgressBar.IsIndeterminate = $false
                if ($callbackUi.ProgressBar.Value -lt 1) { $callbackUi.ProgressBar.Value = 100 }
                $callbackUi.ProgressText.Text = $callbackText.Failed
                $callbackUi.ResultStatus.Text = $callbackText.Failed
                $callbackUi.ResultStatus.Foreground = '#EF7C86'
                $callbackUi.StatusLine.Text = "$($callbackText.ExitCode): $exitCode"
            }
            $callbackState.Process = $null
            $callbackState.CancelRequested = $false
        }.GetNewClosure()
        $onProcessError = { param($message) $callbackUi.StatusLine.Text = $message }.GetNewClosure()
        try { $state.Process = Start-CkLoggedProcess -FileName $state.CliPath -Arguments $args -WorkingDirectory $state.ToolRoot -Dispatcher $Context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onProcessError } catch { & $setRunningAction $false; throw }
    }

    $setRunningAction = (Get-Command Set-EnhancedRunning).ScriptBlock.GetNewClosure()
    $updatePreviewAction = (Get-Command Update-EnhancedCommandPreview).ScriptBlock.GetNewClosure()
    $startAction = (Get-Command Start-EnhancedConversion).ScriptBlock.GetNewClosure()
    $stopAction = { if (-not $state.Process -or $state.Process.Process.HasExited) { return }; $state.CancelRequested = $true; $ui.StopButton.IsEnabled = $false; $pidToStop = $state.Process.Process.Id; $killerInfo = New-Object Diagnostics.ProcessStartInfo; $killerInfo.FileName = 'taskkill.exe'; $killerInfo.Arguments = "/PID $pidToStop /T /F"; $killerInfo.UseShellExecute = $false; $killerInfo.CreateNoWindow = $true; $killer = [Diagnostics.Process]::Start($killerInfo); $killer.WaitForExit(3000) | Out-Null }.GetNewClosure()

    Register-CkButtonAction -Button $ui.ChooseInputFileButton -Action $chooseInputFileAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseInputFolderButton -Action $chooseInputFolderAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseOutputButton -Action $chooseOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenOutputButton -Action $openOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StartButton -Action { & $startAction } -OnError $showPageError
    Register-CkButtonAction -Button $ui.StopButton -Action $stopAction -OnError $showPageError
    Register-CkTextChangedAction -TextBox $ui.InputBox -Action $updatePreviewAction
    Register-CkTextChangedAction -TextBox $ui.OutputBox -Action $updatePreviewAction
    Register-CkTextChangedAction -TextBox $ui.ThreadsBox -Action $updatePreviewAction
    Update-EnhancedEnvironment
    Update-EnhancedCommandPreview
    return $root
}