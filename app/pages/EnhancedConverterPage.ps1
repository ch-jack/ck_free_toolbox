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
        Subtitle = T '4F7F 7528 0020 0046 0069 0076 0065 004D 0020 5B98 65B9 0020 0041 006C 0063 0068 0065 006D 0069 0073 0074 0020 0043 004C 0049 0020 6279 91CF 8F6C 6362 FF0C 6216 5728 975E 8F6C 6362 6A21 5F0F 4E0B 4F18 5316 8D44 6E90'
        Checking = T '68C0 6D4B 4E2D'
        Ready = T '0041 006C 0063 0068 0065 006D 0069 0073 0074 0020 0043 004C 0049 0020 5DF2 5C31 7EEA'
        Missing = T '7F3A 5C11 0020 0041 006C 0063 0068 0065 006D 0069 0073 0074 0043 006C 0069 002E 0065 0078 0065'
        InputLabel = T '8F93 5165 6587 4EF6 6216 76EE 5F55'
        OutputLabel = T '8F93 51FA 76EE 5F55'
        ChooseFile = T '9009 62E9 6587 4EF6'
        ChooseFolder = T '9009 62E9 76EE 5F55'
        OpenOutput = T '6253 5F00 8F93 51FA'
        Params = T '4EFB 52A1 53C2 6570'
        FailOnError = T '5355 6587 4EF6 9047 9519 7ACB 5373 505C 6B62 FF08 002D 002D 0066 0061 0069 006C 002D 006F 006E 002D 0065 0072 0072 006F 0072 FF09'
        FailOnErrorTip = T '53EA 5F71 54CD 5F53 524D 6587 4EF6 FF1B 8BE5 6587 4EF6 5931 8D25 540E 4ECD 7EE7 7EED 4E0B 4E00 4E2A'
        Refine = T '4F18 5316 8D44 6E90 FF08 975E 8F6C 6362 FF09'
        RefineTip = T '002D 002D 0072 0065 0066 0069 006E 0065 FF1A 4F18 5316 8D44 6E90 FF0C 4E0D 6267 884C 8F6C 6362'
        Relaxed = T '5BBD 677E 6A21 5F0F FF08 81EA 52A8 4FEE 590D FF09'
        RelaxedTip = T '002D 002D 0072 0065 006C 0061 0078 0065 0064 FF1A 81EA 52A8 4FEE 590D 5E76 964D 4F4E 4E25 683C 68C0 67E5'
        Threads = T '7EBF 7A0B 6570 FF08 002D 006A 004E FF0C 9ED8 8BA4 0020 0031 0032 FF09'
        Overwrite = T '8986 76D6 73B0 6709 6587 4EF6 0028 002D 0066 0029'
        OverwriteTip = T '672A 542F 7528 65F6 8DF3 8FC7 5DF2 5B58 5728 7684 540C 540D 8F93 51FA 6587 4EF6'
        Telemetry = T '5DF2 968F 9644 0020 0061 006C 0063 0068 0065 006D 0069 0073 0074 002D 0063 006F 006E 0066 0069 0067 002E 0074 0078 0074 0020 542F 7528 5B98 65B9 9065 6D4B 3002'
        StartConvert = T '5F00 59CB 8F6C 6362'
        StartOptimize = T '5F00 59CB 4F18 5316'
        Stop = T '505C 6B62 4EFB 52A1'
        Waiting = T '7B49 5F85 4EFB 52A1'
        Running = T '6B63 5728 8FD0 884C'
        Stopping = T '6B63 5728 505C 6B62'
        Stopped = T '5DF2 505C 6B62'
        DoneConvert = T '8F6C 6362 5B8C 6210'
        DoneOptimize = T '4F18 5316 5B8C 6210'
        Failed = T '4EFB 52A1 5931 8D25'
        OperationFailed = T '64CD 4F5C 5931 8D25'
        ProgressTitle = T '4EFB 52A1 8FDB 5EA6'
        StatusIdle = T '9009 62E9 8F93 5165 548C 8F93 51FA 540E 5F00 59CB 4EFB 52A1 3002'
        Logs = T '4EFB 52A1 65E5 5FD7'
        LogWaiting = T '7B49 5F85 4EFB 52A1 8F93 51FA 002E 002E 002E'
        Command = T '547D 4EE4 9884 89C8'
        InputMissing = T '8BF7 9009 62E9 5B58 5728 7684 8F93 5165 6587 4EF6 6216 76EE 5F55 3002'
        OutputMissing = T '8BF7 9009 62E9 8F93 51FA 76EE 5F55 3002'
        InvalidThreads = T '7EBF 7A0B 6570 5FC5 987B 662F 0020 0031 002D 0031 0030 0032 0034 0020 4E4B 95F4 7684 6574 6570 3002'
        CliMissing = T '627E 4E0D 5230 0020 0041 006C 0063 0068 0065 006D 0069 0073 0074 0043 006C 0069 002E 0065 0078 0065 3002'
        StartingConvert = T '5F00 59CB 8F6C 6362 002E 002E 002E'
        StartingOptimize = T '5F00 59CB 4F18 5316 002E 002E 002E'
        ExitCode = T '8FDB 7A0B 9000 51FA 7801'
        BrowseInputFile = T '9009 62E9 9700 8981 8F6C 6362 7684 8F93 5165 6587 4EF6'
        BrowseInputFolder = T '9009 62E9 9700 8981 8F6C 6362 7684 8F93 5165 76EE 5F55'
        BrowseOutput = T '9009 62E9 8F93 51FA 76EE 5F55'
        FailedDirectoryLabel = T '5931 8D25 6587 4EF6 76EE 5F55'
        MoveFailed = T '5931 8D25 540E 79FB 52A8 539F 6587 4EF6 5E76 7EE7 7EED'
        MoveFailedTip = T '4FDD 7559 76F8 5BF9 76EE 5F55 FF1B 540C 540D 6587 4EF6 81EA 52A8 589E 52A0 540E 7F00'
        BrowseFailed = T '9009 62E9 5931 8D25 6587 4EF6 76EE 5F55'
        OpenFailed = T '6253 5F00 5931 8D25 76EE 5F55'
        ViewReport = T '67E5 770B 62A5 544A'
        ReportMissing = T '672C 6B21 4EFB 52A1 62A5 544A 4E0D 5B58 5728 3002'
        FailedDirectoryMissing = T '8BF7 6307 5B9A 5931 8D25 6587 4EF6 76EE 5F55 3002'
        FailedDirectoryConflict = T '5931 8D25 6587 4EF6 76EE 5F55 5FC5 987B 4E0E 8F93 5165 3001 8F93 51FA 76EE 5F55 5206 5F00 FF0C 4E14 4E0D 80FD 4F4D 4E8E 5B83 4EEC 5185 90E8 3002'
        WorkerMissing = T '627E 4E0D 5230 9010 6587 4EF6 8F6C 6362 5904 7406 5668 3002'
        PartialDone = T '5B8C 6210 FF0C 90E8 5206 5931 8D25'
        ContinueHint = T '4EC5 8F6C 6362 0020 0047 0054 0041 0035 0020 6A21 7EC4 8D44 6E90 FF1B 4EE3 7801 548C 914D 7F6E 539F 6837 590D 5236 FF0C 5931 8D25 6A21 7EC4 79FB 8D70 540E 7EE7 7EED 4E0B 4E00 4E2A 3002'
        ConvertedCount = T '8F6C 6362'
        CopiedCount = T '539F 6837 590D 5236'
        FailedCount = T '5931 8D25'
        SkippedCount = T '8DF3 8FC7'
        UnmovedCount = T '79FB 52A8 5931 8D25'
        ReportReady = T '62A5 544A 5DF2 751F 6210'
        AlreadyRunning = T '5DF2 6709 4EFB 52A1 6B63 5728 8FD0 884C 3002'
        OutputNotDirectory = T '8F93 51FA 8DEF 5F84 5FC5 987B 662F 76EE 5F55 3002'
        InputSameOutput = T '8F93 5165 548C 8F93 51FA 4E0D 80FD 6307 5411 540C 4E00 8DEF 5F84 3002'
        OutputInsideInput = T '8F93 51FA 76EE 5F55 4E0D 80FD 4F4D 4E8E 8F93 5165 76EE 5F55 5185 90E8 FF0C 5426 5219 4F1A 91CD 590D 5904 7406 8F93 51FA 6587 4EF6 3002'
        InputRootDenied = T '4E0D 80FD 5904 7406 6574 4E2A 78C1 76D8 FF0C 8BF7 9009 62E9 5177 4F53 7684 8F93 5165 76EE 5F55 3002'
        OutputRootDenied = T '4E0D 80FD 76F4 63A5 8F93 51FA 5230 78C1 76D8 6839 76EE 5F55 3002'
        Collision = T '8F93 51FA 4E2D 5DF2 5B58 5728 540C 540D 6587 4EF6 3002 8BF7 9009 62E9 7A7A 76EE 5F55 6216 542F 7528 201C 8986 76D6 73B0 6709 6587 4EF6 FF08 002D 0066 FF09 201D 3002'
        Scanning = T '6B63 5728 626B 63CF 8F93 5165 6587 4EF6 002E 002E 002E'
        Processed = T '5DF2 5904 7406'
        FileUnit = T '4E2A 6587 4EF6'
        Current = T '5F53 524D'
        CallbackError = T '8FDB 7A0B 56DE 8C03 9519 8BEF'
        StopFailed = T '505C 6B62 4EFB 52A1 5931 8D25'
    }

    $state = [pscustomobject]@{
        Process = $null
        CancelRequested = $false
        TotalFiles = 0
        ProcessedFiles = 0
        SuccessFiles = 0
        ConvertedFiles = 0
        CopiedFiles = 0
        FailedFiles = 0
        SkippedFiles = 0
        UnmovedFiles = 0
        IsOptimize = $false
        ReportPath = ''
        CliPath = Join-Path $Context.Paths.AppRoot 'tools\alchemist\AlchemistCli.exe'
        WorkerPath = Join-Path $Context.Paths.AppRoot 'tools\alchemist\AlchemistBatchWorker.ps1'
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
        <CheckBox x:Name="MoveFailedBox" Content="$($text.MoveFailed)" IsChecked="True" Margin="0,14,0,8" ToolTip="$($text.MoveFailedTip)"/>
        <TextBlock Text="$($text.FailedDirectoryLabel)" Foreground="#B8C0CC" FontSize="13" Margin="0,0,0,6"/>
        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><TextBox x:Name="FailedDirectoryBox" Height="38"/><Button x:Name="ChooseFailedDirectoryButton" Grid.Column="1" Content="$($text.ChooseFolder)" Height="38" Margin="8,0,0,0" Background="#3A2514" Foreground="#F4B860"/><Button x:Name="OpenFailedDirectoryButton" Grid.Column="2" Content="$($text.OpenFailed)" Height="38" Margin="8,0,0,0"/></Grid>
        <TextBlock Text="$($text.ContinueHint)" Foreground="#6E7580" FontSize="12" Margin="0,8,0,0"/>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="$($text.Params)" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="180"/></Grid.ColumnDefinitions><CheckBox x:Name="FailOnErrorBox" Content="$($text.FailOnError)" ToolTip="$($text.FailOnErrorTip)"/><CheckBox x:Name="RefineBox" Grid.Column="1" Content="$($text.Refine)" ToolTip="$($text.RefineTip)"/><CheckBox x:Name="RelaxedBox" Grid.Column="2" Content="$($text.Relaxed)" ToolTip="$($text.RelaxedTip)"/><StackPanel Grid.Column="3"><TextBlock Text="$($text.Threads)" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="ThreadsBox" Height="34" Text="12"/></StackPanel></Grid>
        <CheckBox x:Name="OverwriteBox" Content="$($text.Overwrite)" IsChecked="True" Margin="0,14,0,0" ToolTip="$($text.OverwriteTip)"/>
        <TextBlock Text="$($text.Telemetry)" Foreground="#6E7580" FontSize="12" Margin="0,10,0,0"/>
      </StackPanel>
    </Border>

    <Grid Margin="0,0,0,14"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="140"/><ColumnDefinition Width="140"/></Grid.ColumnDefinitions><Button x:Name="StartButton" Content="$($text.StartConvert)" Height="46" FontWeight="Bold" Background="#173055" Foreground="#58A6FF"/><Button x:Name="StopButton" Grid.Column="1" Content="$($text.Stop)" Height="46" Margin="8,0,0,0" Foreground="#F28B94" IsEnabled="False"/><Button x:Name="OpenReportButton" Grid.Column="2" Content="$($text.ViewReport)" Height="46" Margin="8,0,0,0" Foreground="#9B7BFF" IsEnabled="False"/></Grid>

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
    $ui = Get-CkNamedControls -Root $root -Names @('EnvironmentDot','EnvironmentText','InputBox','ChooseInputFileButton','ChooseInputFolderButton','OutputBox','ChooseOutputButton','OpenOutputButton','MoveFailedBox','FailedDirectoryBox','ChooseFailedDirectoryButton','OpenFailedDirectoryButton','FailOnErrorBox','RefineBox','RelaxedBox','ThreadsBox','OverwriteBox','StartButton','StopButton','OpenReportButton','ResultStatus','ProgressBar','ProgressText','StatusLine','CommandBox','LogBox')

    $desktopPath = [Environment]::GetFolderPath('Desktop')
    if ([string]::IsNullOrWhiteSpace($desktopPath)) {
        $desktopPath = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE 'Desktop' } else { [IO.Path]::GetTempPath() }
    }
    $ui.OutputBox.Text = Join-Path $desktopPath 'AlchemistOutput'
    $ui.FailedDirectoryBox.Text = Join-Path $desktopPath 'AlchemistFailed'

    $getExistingDirectoryAction = {
        param([string]$Path)

        if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
        try {
            $candidate = [IO.Path]::GetFullPath($Path.Trim())
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $candidate = Split-Path -Parent $candidate
            }
            while ($candidate -and -not (Test-Path -LiteralPath $candidate -PathType Container)) {
                $parent = [IO.Directory]::GetParent($candidate)
                if (-not $parent) { break }
                $candidate = $parent.FullName
            }
            if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Container)) {
                return $candidate
            }
        } catch { }
        return ''
    }.GetNewClosure()

    $getInvocationAction = {
        param([bool]$Validate)

        $inputValue = ([string]$ui.InputBox.Text).Trim()
        $outputValue = ([string]$ui.OutputBox.Text).Trim()
        $failedValue = ([string]$ui.FailedDirectoryBox.Text).Trim()
        $moveFailed = ($ui.MoveFailedBox.IsChecked -eq $true)
        if ($Validate -and [string]::IsNullOrWhiteSpace($inputValue)) { throw $text.InputMissing }
        if ($Validate -and [string]::IsNullOrWhiteSpace($outputValue)) { throw $text.OutputMissing }
        if ($Validate -and $moveFailed -and [string]::IsNullOrWhiteSpace($failedValue)) { throw $text.FailedDirectoryMissing }
        if ($Validate -and -not (Test-Path -LiteralPath $state.CliPath -PathType Leaf)) { throw $text.CliMissing }
        if ($Validate -and -not (Test-Path -LiteralPath $state.WorkerPath -PathType Leaf)) { throw $text.WorkerMissing }

        $inputPath = $inputValue
        if ($inputValue) {
            try { $inputPath = [IO.Path]::GetFullPath($inputValue) } catch {
                if ($Validate) { throw $text.InputMissing }
            }
        }

        $outputDirectory = $outputValue
        if ($outputValue) {
            try { $outputDirectory = [IO.Path]::GetFullPath($outputValue) } catch {
                if ($Validate) { throw $text.OutputMissing }
            }
        }

        $failedDirectory = $failedValue
        if ($failedValue) {
            try { $failedDirectory = [IO.Path]::GetFullPath($failedValue) } catch {
                if ($Validate -and $moveFailed) { throw $text.FailedDirectoryMissing }
            }
        }

        $inputIsFile = $inputPath -and (Test-Path -LiteralPath $inputPath -PathType Leaf)
        $inputIsDirectory = $inputPath -and (Test-Path -LiteralPath $inputPath -PathType Container)
        if ($Validate -and -not $inputIsFile -and -not $inputIsDirectory) { throw $text.InputMissing }
        if ($Validate -and $outputDirectory -and (Test-Path -LiteralPath $outputDirectory -PathType Leaf)) { throw $text.OutputNotDirectory }
        if ($Validate -and $moveFailed -and $failedDirectory -and (Test-Path -LiteralPath $failedDirectory -PathType Leaf)) { throw $text.FailedDirectoryMissing }

        [int]$threads = 0
        $threadsValue = ([string]$ui.ThreadsBox.Text).Trim()
        $validThreads = [int]::TryParse($threadsValue, [ref]$threads) -and $threads -ge 1 -and $threads -le 1024
        if ($Validate -and -not $validThreads) { throw $text.InvalidThreads }
        $threadArgument = if ($validThreads) { [string]$threads } elseif ($threadsValue) { $threadsValue } else { '12' }

        $effectiveOutputPath = $outputDirectory
        if ($inputIsFile -and $outputDirectory) {
            $effectiveOutputPath = Join-Path $outputDirectory ([IO.Path]::GetFileName($inputPath))
        }

        if ($Validate) {
            $trimChars = [char[]]@('\', '/')
            $outputComparable = $outputDirectory.TrimEnd($trimChars)
            $outputRoot = ([IO.Path]::GetPathRoot($outputDirectory)).TrimEnd($trimChars)
            if ($outputComparable.Equals($outputRoot, [StringComparison]::OrdinalIgnoreCase)) { throw $text.OutputRootDenied }

            $inputComparable = $inputPath.TrimEnd($trimChars)
            if ($inputIsDirectory) {
                $inputRoot = ([IO.Path]::GetPathRoot($inputPath)).TrimEnd($trimChars)
                if ($inputComparable.Equals($inputRoot, [StringComparison]::OrdinalIgnoreCase)) { throw $text.InputRootDenied }
                if ($inputComparable.Equals($outputComparable, [StringComparison]::OrdinalIgnoreCase)) { throw $text.InputSameOutput }
                $inputPrefix = $inputComparable + [IO.Path]::DirectorySeparatorChar
                if ($outputComparable.StartsWith($inputPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw $text.OutputInsideInput }
            } elseif ($effectiveOutputPath.Equals($inputPath, [StringComparison]::OrdinalIgnoreCase)) {
                throw $text.InputSameOutput
            }

            if ($moveFailed) {
                $failedComparable = $failedDirectory.TrimEnd($trimChars)
                $inputPrefix = $inputComparable + [IO.Path]::DirectorySeparatorChar
                $outputPrefix = $outputComparable + [IO.Path]::DirectorySeparatorChar
                $failedPrefix = $failedComparable + [IO.Path]::DirectorySeparatorChar
                $conflict = (
                    $failedComparable.Equals($inputComparable, [StringComparison]::OrdinalIgnoreCase) -or
                    $failedComparable.Equals($outputComparable, [StringComparison]::OrdinalIgnoreCase) -or
                    $failedComparable.StartsWith($inputPrefix, [StringComparison]::OrdinalIgnoreCase) -or
                    $failedComparable.StartsWith($outputPrefix, [StringComparison]::OrdinalIgnoreCase) -or
                    $inputComparable.StartsWith($failedPrefix, [StringComparison]::OrdinalIgnoreCase) -or
                    $outputComparable.StartsWith($failedPrefix, [StringComparison]::OrdinalIgnoreCase)
                )
                if ($conflict) { throw $text.FailedDirectoryConflict }
            }
        }

        $arguments = New-Object System.Collections.Generic.List[object]
        if ($ui.FailOnErrorBox.IsChecked -eq $true) { $arguments.Add('--fail-on-error') }
        if ($ui.RefineBox.IsChecked -eq $true) { $arguments.Add('--refine') }
        if ($ui.RelaxedBox.IsChecked -eq $true) { $arguments.Add('--relaxed') }
        if ($ui.OverwriteBox.IsChecked -eq $true) { $arguments.Add('-f') }
        $arguments.Add(('-j{0}' -f $threadArgument))
        $arguments.Add($(if ($inputPath) { $inputPath } else { '<each-input-file>' }))
        $arguments.Add($(if ($effectiveOutputPath) { $effectiveOutputPath } else { '<matching-output-file>' }))

        return [pscustomobject]@{
            Arguments = [object[]]$arguments.ToArray()
            InputPath = $inputPath
            OutputDirectory = $outputDirectory
            FailedDirectory = $failedDirectory
            EffectiveOutputPath = $effectiveOutputPath
            InputIsFile = [bool]$inputIsFile
            InputIsDirectory = [bool]$inputIsDirectory
            IsOptimize = ($ui.RefineBox.IsChecked -eq $true)
            Overwrite = ($ui.OverwriteBox.IsChecked -eq $true)
            MoveFailed = $moveFailed
            Threads = if ($validThreads) { $threads } else { 12 }
        }
    }.GetNewClosure()

    $updatePreviewAction = {
        try {
            $invocation = & $getInvocationAction $false
            $preview = 'AlchemistCli.exe ' + (Join-CkArgumentList -Arguments $invocation.Arguments)
            if ($invocation.MoveFailed -and $invocation.FailedDirectory) {
                $preview += '  | failed -> ' + (Join-CkArgumentList -Arguments @($invocation.FailedDirectory))
            }
            $ui.CommandBox.Text = $preview
        } catch {
            $ui.CommandBox.Text = $_.Exception.Message
        }
    }.GetNewClosure()

    $setRunningAction = {
        param([bool]$Running)

        foreach ($control in @(
            $ui.InputBox,
            $ui.ChooseInputFileButton,
            $ui.ChooseInputFolderButton,
            $ui.OutputBox,
            $ui.ChooseOutputButton,
            $ui.MoveFailedBox,
            $ui.FailOnErrorBox,
            $ui.RefineBox,
            $ui.RelaxedBox,
            $ui.ThreadsBox,
            $ui.OverwriteBox,
            $ui.StartButton
        )) {
            $control.IsEnabled = -not $Running
        }
        $failedControlsEnabled = (-not $Running) -and ($ui.MoveFailedBox.IsChecked -eq $true)
        foreach ($control in @($ui.FailedDirectoryBox, $ui.ChooseFailedDirectoryButton, $ui.OpenFailedDirectoryButton)) {
            $control.IsEnabled = $failedControlsEnabled
        }
        $ui.StopButton.IsEnabled = $Running
        $ui.OpenReportButton.IsEnabled = (-not $Running) -and $state.ReportPath -and (Test-Path -LiteralPath $state.ReportPath -PathType Leaf)

        if ($Running) {
            $ui.ProgressBar.Value = 0
            $ui.ProgressBar.IsIndeterminate = ($state.TotalFiles -le 0)
            $ui.ProgressText.Text = if ($state.TotalFiles -gt 0) { "0% (0/$($state.TotalFiles))" } else { $text.Running }
            $ui.ResultStatus.Text = $text.Running
            $ui.ResultStatus.Foreground = '#58A6FF'
            $ui.StatusLine.Text = if ($state.IsOptimize) { $text.StartingOptimize } else { $text.StartingConvert }
        } else {
            $ui.ProgressBar.IsIndeterminate = $false
        }
    }.GetNewClosure()

    $scanInputAction = {
        param($Invocation)

        if ($Invocation.InputIsFile) { return 1 }
        return @(Get-ChildItem -LiteralPath $Invocation.InputPath -File -Recurse -Force -ErrorAction Stop).Count
    }.GetNewClosure()

    $chooseInputFileAction = {
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = $text.BrowseInputFile
        $dialog.Filter = 'All files (*.*)|*.*'
        $dialog.Multiselect = $false
        $dialog.RestoreDirectory = $true
        $initialDirectory = & $getExistingDirectoryAction $ui.InputBox.Text
        if ($initialDirectory) { $dialog.InitialDirectory = $initialDirectory }
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $ui.InputBox.Text = $dialog.FileName
            }
        } finally {
            $dialog.Dispose()
        }
    }.GetNewClosure()

    $chooseInputFolderAction = {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = $text.BrowseInputFolder
        $dialog.ShowNewFolderButton = $false
        $initialDirectory = & $getExistingDirectoryAction $ui.InputBox.Text
        if ($initialDirectory) { $dialog.SelectedPath = $initialDirectory }
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $ui.InputBox.Text = $dialog.SelectedPath
            }
        } finally {
            $dialog.Dispose()
        }
    }.GetNewClosure()

    $chooseOutputAction = {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = $text.BrowseOutput
        $dialog.ShowNewFolderButton = $true
        $initialDirectory = & $getExistingDirectoryAction $ui.OutputBox.Text
        if ($initialDirectory) { $dialog.SelectedPath = $initialDirectory }
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $ui.OutputBox.Text = $dialog.SelectedPath
            }
        } finally {
            $dialog.Dispose()
        }
    }.GetNewClosure()

    $chooseFailedDirectoryAction = {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = $text.BrowseFailed
        $dialog.ShowNewFolderButton = $true
        $initialDirectory = & $getExistingDirectoryAction $ui.FailedDirectoryBox.Text
        if ($initialDirectory) { $dialog.SelectedPath = $initialDirectory }
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $ui.FailedDirectoryBox.Text = $dialog.SelectedPath
            }
        } finally {
            $dialog.Dispose()
        }
    }.GetNewClosure()

    $openFailedDirectoryAction = {
        $path = ([string]$ui.FailedDirectoryBox.Text).Trim()
        if (-not $path) { throw $text.FailedDirectoryMissing }
        try { $path = [IO.Path]::GetFullPath($path) } catch { throw $text.FailedDirectoryMissing }
        if (Test-Path -LiteralPath $path -PathType Leaf) { throw $text.FailedDirectoryMissing }
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            New-Item -ItemType Directory -Path $path -Force -ErrorAction Stop | Out-Null
        }
        Start-Process -FilePath explorer.exe -ArgumentList @($path)
    }.GetNewClosure()

    $openReportAction = {
        $path = [string]$state.ReportPath
        if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { throw $text.ReportMissing }
        Start-Process -FilePath $path -ErrorAction Stop
    }.GetNewClosure()

    $openOutputAction = {
        $path = ([string]$ui.OutputBox.Text).Trim()
        if (-not $path) { throw $text.OutputMissing }
        try { $path = [IO.Path]::GetFullPath($path) } catch { throw $text.OutputMissing }
        if (Test-Path -LiteralPath $path -PathType Leaf) { throw $text.OutputNotDirectory }
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            New-Item -ItemType Directory -Path $path -Force -ErrorAction Stop | Out-Null
        }
        Start-Process -FilePath explorer.exe -ArgumentList @($path)
    }.GetNewClosure()

    $showPageError = {
        param([string]$message)

        $ui.ResultStatus.Text = $text.OperationFailed
        $ui.ResultStatus.Foreground = '#EF7C86'
        $ui.StatusLine.Text = $message
        Add-CkLogLine -TextBox $ui.LogBox -Line "[toolbox] $message"
        [System.Windows.MessageBox]::Show(
            $message,
            "CKFreeToolbox - $($text.Title)",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }.GetNewClosure()

    $startAction = {
        if ($state.Process -and -not $state.Process.Process.HasExited) { throw $text.AlreadyRunning }

        $invocation = & $getInvocationAction $true
        $ui.StatusLine.Text = $text.Scanning
        $totalFiles = & $scanInputAction $invocation
        if (-not (Test-Path -LiteralPath $invocation.OutputDirectory -PathType Container)) {
            New-Item -ItemType Directory -Path $invocation.OutputDirectory -Force -ErrorAction Stop | Out-Null
        }
        if ($invocation.MoveFailed -and -not (Test-Path -LiteralPath $invocation.FailedDirectory -PathType Container)) {
            New-Item -ItemType Directory -Path $invocation.FailedDirectory -Force -ErrorAction Stop | Out-Null
        }

        $reportDirectory = Join-Path $invocation.OutputDirectory '_alchemist_reports'
        $reportName = 'alchemist-report-{0}.html' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
        $reportPath = Join-Path $reportDirectory $reportName
        $state.CancelRequested = $false
        $state.TotalFiles = [int]$totalFiles
        $state.ProcessedFiles = 0
        $state.SuccessFiles = 0
        $state.ConvertedFiles = 0
        $state.CopiedFiles = 0
        $state.FailedFiles = 0
        $state.SkippedFiles = 0
        $state.UnmovedFiles = 0
        $state.IsOptimize = [bool]$invocation.IsOptimize
        $state.ReportPath = $reportPath
        $ui.OpenReportButton.IsEnabled = $false

        $startingText = if ($state.IsOptimize) { $text.StartingOptimize } else { $text.StartingConvert }
        $logLines = New-Object System.Collections.Generic.List[string]
        $logLines.Add($startingText)
        $logLines.Add("Input: $($invocation.InputPath)")
        $logLines.Add("Output: $($invocation.OutputDirectory)")
        if ($invocation.MoveFailed) { $logLines.Add("Failed files: $($invocation.FailedDirectory)") }
        $logLines.Add("Report: $reportPath")
        $logLines.Add("Per-file command: AlchemistCli.exe $(Join-CkArgumentList -Arguments $invocation.Arguments)")
        $ui.LogBox.Text = $logLines -join [Environment]::NewLine
        & $setRunningAction $true

        $powershellExe = Join-Path $PSHOME 'powershell.exe'
        if (-not (Test-Path -LiteralPath $powershellExe -PathType Leaf)) {
            $powershellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        }
        $workerArguments = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $state.WorkerPath,
            '-CliPath', $state.CliPath,
            '-InputPath', $invocation.InputPath,
            '-OutputDirectory', $invocation.OutputDirectory,
            '-ReportPath', $reportPath,
            '-Threads', [string]$invocation.Threads
        )
        if ($ui.FailOnErrorBox.IsChecked -eq $true) { $workerArguments += '-FailOnError' }
        if ($invocation.IsOptimize) { $workerArguments += '-Refine' }
        if ($ui.RelaxedBox.IsChecked -eq $true) { $workerArguments += '-Relaxed' }
        if ($invocation.Overwrite) { $workerArguments += '-Overwrite' }
        if ($invocation.MoveFailed) {
            $workerArguments += @('-FailedDirectory', $invocation.FailedDirectory, '-MoveFailed')
        }

        $callbackUi = $ui
        $callbackText = $text
        $callbackState = $state
        $callbackSetRunning = $setRunningAction
        $callbackDone = if ($invocation.IsOptimize) { $text.DoneOptimize } else { $text.DoneConvert }
        $callbackFailedDirectory = $invocation.FailedDirectory
        $callbackMoveFailed = $invocation.MoveFailed

        $onOutput = {
            param($line)

            Add-CkLogLine -TextBox $callbackUi.LogBox -Line $line
            if ($line -match '^\[ck-file\]\s+index=(?<index>\d+)\s+total=(?<total>\d+)\s+kind=(?<kind>\S+)\s+file=(?<file>.*)$') {
                $callbackUi.StatusLine.Text = "$($callbackText.Current): $($Matches.file)"
            } elseif ($line -match '^\[ck-progress\]\s+processed=(?<processed>\d+)\s+total=(?<total>\d+)\s+success=(?<success>\d+)\s+converted=(?<converted>\d+)\s+copied=(?<copied>\d+)\s+failed=(?<failed>\d+)\s+skipped=(?<skipped>\d+)\s+unmoved=(?<unmoved>\d+)\s+file=(?<file>.*)$') {
                $callbackState.ProcessedFiles = [int]$Matches.processed
                $callbackState.TotalFiles = [int]$Matches.total
                $callbackState.SuccessFiles = [int]$Matches.success
                $callbackState.ConvertedFiles = [int]$Matches.converted
                $callbackState.CopiedFiles = [int]$Matches.copied
                $callbackState.FailedFiles = [int]$Matches.failed
                $callbackState.SkippedFiles = [int]$Matches.skipped
                $callbackState.UnmovedFiles = [int]$Matches.unmoved
                $percent = if ($callbackState.TotalFiles -gt 0) {
                    [Math]::Min(99, [Math]::Floor(($callbackState.ProcessedFiles * 100.0) / $callbackState.TotalFiles))
                } else { 99 }
                $callbackUi.ProgressBar.IsIndeterminate = $false
                $callbackUi.ProgressBar.Value = $percent
                $callbackUi.ProgressText.Text = ('{0:0}% ({1}/{2})' -f $percent, $callbackState.ProcessedFiles, $callbackState.TotalFiles)
                $callbackUi.StatusLine.Text = "$($callbackText.Processed) $($callbackState.ProcessedFiles)/$($callbackState.TotalFiles) $($callbackText.FileUnit) | $($callbackText.ConvertedCount) $($callbackState.ConvertedFiles) | $($callbackText.CopiedCount) $($callbackState.CopiedFiles) | $($callbackText.FailedCount) $($callbackState.FailedFiles) | $($callbackText.SkippedCount) $($callbackState.SkippedFiles)"
            } elseif ($line -match '^\[ck-report\]\s+path=(?<path>.+)$') {
                $callbackState.ReportPath = $Matches.path.Trim()
            } elseif ($line -match '^\[ck-summary\]\s+total=(?<total>\d+)\s+success=(?<success>\d+)\s+converted=(?<converted>\d+)\s+copied=(?<copied>\d+)\s+failed=(?<failed>\d+)\s+skipped=(?<skipped>\d+)\s+unmoved=(?<unmoved>\d+)$') {
                $callbackState.TotalFiles = [int]$Matches.total
                $callbackState.ProcessedFiles = $callbackState.TotalFiles
                $callbackState.SuccessFiles = [int]$Matches.success
                $callbackState.ConvertedFiles = [int]$Matches.converted
                $callbackState.CopiedFiles = [int]$Matches.copied
                $callbackState.FailedFiles = [int]$Matches.failed
                $callbackState.SkippedFiles = [int]$Matches.skipped
                $callbackState.UnmovedFiles = [int]$Matches.unmoved
            } elseif ($line -match '^\[ck-fatal\]\s+(?<message>.+)$') {
                $callbackUi.StatusLine.Text = $Matches.message
            }
        }.GetNewClosure()

        $onExit = {
            param($exitCode)

            $cancelled = $callbackState.CancelRequested
            $callbackState.Process = $null
            $callbackState.CancelRequested = $false
            & $callbackSetRunning $false
            $reportExists = $callbackState.ReportPath -and (Test-Path -LiteralPath $callbackState.ReportPath -PathType Leaf)
            $summary = "$($callbackText.ConvertedCount) $($callbackState.ConvertedFiles) | $($callbackText.CopiedCount) $($callbackState.CopiedFiles) | $($callbackText.FailedCount) $($callbackState.FailedFiles) | $($callbackText.SkippedCount) $($callbackState.SkippedFiles)"
            if ($callbackState.UnmovedFiles -gt 0) {
                $summary += " | $($callbackText.UnmovedCount) $($callbackState.UnmovedFiles)"
            }

            if ($cancelled) {
                $callbackUi.ResultStatus.Text = $callbackText.Stopped
                $callbackUi.ResultStatus.Foreground = '#F4B860'
                $callbackUi.StatusLine.Text = "$($callbackText.Stopped) | $summary"
            } elseif ($callbackState.FailedFiles -gt 0 -and $callbackState.ProcessedFiles -ge $callbackState.TotalFiles) {
                $callbackUi.ProgressBar.Value = 100
                $callbackUi.ProgressText.Text = "100% ($($callbackState.ProcessedFiles)/$($callbackState.TotalFiles))"
                $callbackUi.ResultStatus.Text = $callbackText.PartialDone
                $callbackUi.ResultStatus.Foreground = '#F4B860'
                $callbackUi.StatusLine.Text = $summary
                if ($callbackMoveFailed) {
                    $callbackUi.StatusLine.Text += " | $($callbackText.FailedDirectoryLabel): $callbackFailedDirectory"
                }
            } elseif ($exitCode -eq 0) {
                $callbackUi.ProgressBar.Value = 100
                $callbackUi.ProgressText.Text = if ($callbackState.TotalFiles -gt 0) { "100% ($($callbackState.TotalFiles)/$($callbackState.TotalFiles))" } else { '100%' }
                $callbackUi.ResultStatus.Text = $callbackDone
                $callbackUi.ResultStatus.Foreground = '#31D69A'
                $callbackUi.StatusLine.Text = "$callbackDone | $summary"
            } else {
                $callbackUi.ProgressBar.IsIndeterminate = $false
                if ($callbackState.TotalFiles -le 0) {
                    $callbackUi.ProgressBar.Value = 0
                    $callbackUi.ProgressText.Text = '0%'
                }
                $callbackUi.ResultStatus.Text = $callbackText.Failed
                $callbackUi.ResultStatus.Foreground = '#EF7C86'
                $callbackUi.StatusLine.Text = "$($callbackText.ExitCode): $exitCode | $summary"
            }

            if ($reportExists) {
                Add-CkLogLine -TextBox $callbackUi.LogBox -Line "$($callbackText.ReportReady): $($callbackState.ReportPath)"
                $callbackUi.OpenReportButton.IsEnabled = $true
            }
        }.GetNewClosure()

        $onProcessError = {
            param($message)

            Add-CkLogLine -TextBox $callbackUi.LogBox -Line "[$($callbackText.CallbackError)] $message"
            $callbackUi.StatusLine.Text = $message
        }.GetNewClosure()

        try {
            $state.Process = Start-CkLoggedProcess -FileName $powershellExe -Arguments $workerArguments -WorkingDirectory $state.ToolRoot -Dispatcher $Context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onProcessError
        } catch {
            $state.Process = $null
            & $setRunningAction $false
            throw
        }
    }.GetNewClosure()

    $stopAction = {
        if (-not $state.Process -or $state.Process.Process.HasExited) { return }

        $state.CancelRequested = $true
        $ui.StopButton.IsEnabled = $false
        $ui.ResultStatus.Text = $text.Stopping
        $ui.ResultStatus.Foreground = '#F4B860'
        $ui.StatusLine.Text = $text.Stopping
        $process = $state.Process.Process
        try {
            $killerInfo = New-Object Diagnostics.ProcessStartInfo
            $killerInfo.FileName = 'taskkill.exe'
            $killerInfo.Arguments = "/PID $($process.Id) /T /F"
            $killerInfo.UseShellExecute = $false
            $killerInfo.CreateNoWindow = $true
            $killer = [Diagnostics.Process]::Start($killerInfo)
            if ($killer) {
                [void]$killer.WaitForExit(5000)
                $killer.Dispose()
            }
            if (-not $process.HasExited) { $process.Kill() }
        } catch {
            if (-not $process.HasExited) {
                $state.CancelRequested = $false
                $ui.StopButton.IsEnabled = $true
            }
            throw "$($text.StopFailed): $($_.Exception.Message)"
        }
    }.GetNewClosure()

    $updateModeAction = {
        $ui.StartButton.Content = if ($ui.RefineBox.IsChecked -eq $true) { $text.StartOptimize } else { $text.StartConvert }
        & $updatePreviewAction
    }.GetNewClosure()

    $updateMoveFailedAction = {
        $enabled = ($ui.MoveFailedBox.IsChecked -eq $true) -and (-not $state.Process -or $state.Process.Process.HasExited)
        foreach ($control in @($ui.FailedDirectoryBox, $ui.ChooseFailedDirectoryButton, $ui.OpenFailedDirectoryButton)) {
            $control.IsEnabled = $enabled
        }
        & $updatePreviewAction
    }.GetNewClosure()

    $previewOptionAction = {
        & $updatePreviewAction
    }.GetNewClosure()

    $runAction = {
        & $startAction
    }.GetNewClosure()

    Register-CkButtonAction -Button $ui.ChooseInputFileButton -Action $chooseInputFileAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseInputFolderButton -Action $chooseInputFolderAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseOutputButton -Action $chooseOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenOutputButton -Action $openOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseFailedDirectoryButton -Action $chooseFailedDirectoryAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenFailedDirectoryButton -Action $openFailedDirectoryAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenReportButton -Action $openReportAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StartButton -Action $runAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StopButton -Action $stopAction -OnError $showPageError
    Register-CkTextChangedAction -TextBox $ui.InputBox -Action $updatePreviewAction
    Register-CkTextChangedAction -TextBox $ui.OutputBox -Action $updatePreviewAction
    Register-CkTextChangedAction -TextBox $ui.FailedDirectoryBox -Action $updatePreviewAction
    Register-CkTextChangedAction -TextBox $ui.ThreadsBox -Action $updatePreviewAction

    $refineChangedHandler = {
        & $updateModeAction
    }.GetNewClosure()
    $ui.RefineBox.Add_Checked($refineChangedHandler)
    $ui.RefineBox.Add_Unchecked($refineChangedHandler)

    $moveFailedChangedHandler = {
        & $updateMoveFailedAction
    }.GetNewClosure()
    $ui.MoveFailedBox.Add_Checked($moveFailedChangedHandler)
    $ui.MoveFailedBox.Add_Unchecked($moveFailedChangedHandler)

    $optionChangedHandler = {
        & $previewOptionAction
    }.GetNewClosure()
    foreach ($option in @($ui.FailOnErrorBox, $ui.RelaxedBox, $ui.OverwriteBox)) {
        $option.Add_Checked($optionChangedHandler)
        $option.Add_Unchecked($optionChangedHandler)
    }

    $cliReady = Test-Path -LiteralPath $state.CliPath -PathType Leaf
    $workerReady = Test-Path -LiteralPath $state.WorkerPath -PathType Leaf
    $environmentReady = $cliReady -and $workerReady
    Set-CkStatusDot $ui.EnvironmentDot $environmentReady
    $ui.EnvironmentText.Foreground = if ($environmentReady) { '#31D69A' } else { '#EF6B73' }
    $ui.EnvironmentText.Text = if (-not $cliReady) { $text.Missing } elseif (-not $workerReady) { $text.WorkerMissing } else { $text.Ready }
    $ui.EnvironmentText.ToolTip = $state.CliPath + [Environment]::NewLine + $state.WorkerPath
    & $updateMoveFailedAction
    & $updateModeAction
    return $root
}