function New-CkModelRepairPage {
    param([Parameter(Mandatory)]$Context)

    $reportRoot = Join-Path (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CKFreeToolbox') 'model-repair-reports'
    $state = [pscustomobject]@{
        Process = $null
        CancelRequested = $false
        Ready = $false
        StartedAt = $null
        TargetPath = ''
        NativeLogPath = ''
        ReportRoot = $reportRoot
        ReportPath = ''
        JsonReportPath = ''
        Total = 0
        Current = 0
        Scanned = 0
        Repaired = 0
        Skipped = 0
        Failed = 0
        SummarySeen = $false
        Output = New-Object Text.StringBuilder
    }

    $xaml = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
              xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
              VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"
              Padding="22,16,28,32">
  <StackPanel>
    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12">
          <StackPanel Orientation="Horizontal">
            <Border Width="4" Height="22" CornerRadius="3" Background="#58A6FF" Margin="0,0,10,0"/>
            <StackPanel>
              <TextBlock Text="模型修复" FontSize="21" FontWeight="Bold"/>
              <TextBlock Text="递归修复 FiveM 模型中的受保护 VertexBuffer" Foreground="#8B9099" FontSize="12" Margin="0,4,0,0"/>
            </StackPanel>
          </StackPanel>
          <TextBlock x:Name="EnvironmentStatus" AutomationProperties.AutomationId="ModelRepair.EnvironmentStatus" Text="检测中" HorizontalAlignment="Right" VerticalAlignment="Center" Foreground="#F4B860" FontSize="14" FontWeight="SemiBold"/>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Border Grid.Column="0" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="0,0,5,0">
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/><ColumnDefinition Width="48"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="DotNetDot" Width="9" Height="9" Fill="#F4B860" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1"><TextBlock Text=".NET 8 Runtime" FontSize="14" FontWeight="SemiBold"/><TextBlock x:Name="DotNetText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel>
              <Button x:Name="DotNetButton" AutomationProperties.AutomationId="ModelRepair.DotNetButton" Grid.Column="2" Content="官网" Width="42" Height="27" Foreground="#58A6FF"/>
            </Grid>
          </Border>
          <Border Grid.Column="1" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="5,0,0,0">
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="ComponentDot" Width="9" Height="9" Fill="#F4B860" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1"><TextBlock Text="fxap_only 模型修复组件" FontSize="14" FontWeight="SemiBold"/><TextBlock x:Name="ComponentText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel>
            </Grid>
          </Border>
        </Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="模型目录" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="98"/><ColumnDefinition Width="98"/></Grid.ColumnDefinitions>
          <StackPanel><TextBlock Text="单个 resource、resources 目录或其他模型父目录" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="TargetBox" AutomationProperties.AutomationId="ModelRepair.TargetBox" Height="36"/></StackPanel>
          <Button x:Name="ChooseFolderButton" AutomationProperties.AutomationId="ModelRepair.ChooseFolderButton" Grid.Column="1" Content="选择目录" Height="36" Margin="7,22,0,0" Background="#173055" Foreground="#58A6FF"/>
          <Button x:Name="OpenFolderButton" AutomationProperties.AutomationId="ModelRepair.OpenFolderButton" Grid.Column="2" Content="打开目录" Height="36" Margin="7,22,0,0" IsEnabled="False"/>
        </Grid>
        <TextBlock Text="程序会递归处理 .ydr、.yft、.ydd；已经修复或不需要修复的模型会自动跳过。" Foreground="#8B9099" FontSize="12" Margin="0,9,0,0"/>
      </StackPanel>
    </Border>

    <Border Background="#211713" BorderBrush="#6B4935" BorderThickness="1" CornerRadius="8" Padding="14" Margin="0,0,0,14">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="28"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
        <TextBlock Text="!" Foreground="#F4B860" FontSize="18" FontWeight="Bold" VerticalAlignment="Top"/>
        <StackPanel Grid.Column="1">
          <TextBlock Text="原文件修改与网络说明" Foreground="#F4B860" FontSize="13" FontWeight="SemiBold"/>
          <TextBlock Text="修复成功的模型会在原目录中原子替换；任一 Buffer 失败时该模型原文件保持不变。重要资源请先备份。部分 type 2 VertexBuffer 会上传单个 Buffer 到现有私有修复服务。" Foreground="#C6A98D" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0"/>
        </StackPanel>
      </Grid>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12">
          <TextBlock Text="修复任务" FontSize="18" FontWeight="Bold"/>
          <TextBlock x:Name="ResultStatus" AutomationProperties.AutomationId="ModelRepair.ResultStatus" Text="等待任务" HorizontalAlignment="Right" Foreground="#777B83" FontSize="13" VerticalAlignment="Center"/>
        </Grid>
        <UniformGrid Columns="4" Margin="0,0,0,12">
          <Border Background="#15181C" CornerRadius="6" Padding="10" Margin="0,0,4,0"><StackPanel><TextBlock Text="已扫描" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="ScannedCount" Text="0" FontSize="20" FontWeight="Bold" Foreground="#58A6FF"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="10" Margin="4,0"><StackPanel><TextBlock Text="已修复" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="RepairedCount" Text="0" FontSize="20" FontWeight="Bold" Foreground="#31D69A"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="10" Margin="4,0"><StackPanel><TextBlock Text="无需修复" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="SkippedCount" Text="0" FontSize="20" FontWeight="Bold" Foreground="#9B8CFF"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="10" Margin="4,0,0,0"><StackPanel><TextBlock Text="失败" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="FailedCount" Text="0" FontSize="20" FontWeight="Bold" Foreground="#EF7C86"/></StackPanel></Border>
        </UniformGrid>
        <ProgressBar x:Name="ProgressBar" AutomationProperties.AutomationId="ModelRepair.ProgressBar" Height="8" Minimum="0" Maximum="100" Value="0"/>
        <TextBlock x:Name="StatusLine" AutomationProperties.AutomationId="ModelRepair.StatusLine" Text="选择包含模型文件的目录后开始。" Foreground="#8B9099" FontSize="13" Margin="0,9,0,12" TextWrapping="Wrap"/>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions>
          <Button x:Name="StartButton" AutomationProperties.AutomationId="ModelRepair.StartButton" Content="开始模型修复" Height="44" Margin="0,0,7,0" Background="#124834" Foreground="#54E0A9" FontSize="15" FontWeight="Bold" IsEnabled="False"/>
          <Button x:Name="StopButton" AutomationProperties.AutomationId="ModelRepair.StopButton" Grid.Column="1" Content="停止任务" Height="44" Margin="7,0,0,0" Foreground="#F28B94" IsEnabled="False"/>
        </Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16">
      <StackPanel>
        <Grid Margin="0,0,0,10">
          <TextBlock Text="任务日志" FontSize="18" FontWeight="Bold"/>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
            <Button x:Name="OpenNativeLogButton" AutomationProperties.AutomationId="ModelRepair.OpenNativeLogButton" Content="原生日志" Height="28" Margin="0,0,8,0" IsEnabled="False"/>
            <Button x:Name="OpenReportButton" AutomationProperties.AutomationId="ModelRepair.OpenReportButton" Content="本次报告" Height="28" Margin="0,0,8,0" IsEnabled="False"/>
            <Button x:Name="OpenReportHistoryButton" AutomationProperties.AutomationId="ModelRepair.OpenReportHistoryButton" Content="报告历史" Height="28"/>
          </StackPanel>
        </Grid>
        <TextBox x:Name="LogBox" AutomationProperties.AutomationId="ModelRepair.LogBox" MinHeight="210" MaxHeight="420" AcceptsReturn="True" TextWrapping="NoWrap" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" IsReadOnly="True" Text="等待任务输出..."/>
      </StackPanel>
    </Border>
  </StackPanel>
</ScrollViewer>
"@

    $root = Import-CkXaml $xaml
    $ui = Get-CkNamedControls -Root $root -Names @(
        'EnvironmentStatus','DotNetDot','DotNetText','DotNetButton','ComponentDot','ComponentText',
        'TargetBox','ChooseFolderButton','OpenFolderButton','ResultStatus','ScannedCount','RepairedCount','SkippedCount','FailedCount',
        'ProgressBar','StatusLine','StartButton','StopButton','OpenNativeLogButton','OpenReportButton','OpenReportHistoryButton','LogBox'
    )

    function Get-ModelRepairComponentInfo {
        $required = @(
            'FivemDecryptFixer.Cli.exe','CK.VertexBridge.dll','FivemDecryptFixer.Cli.dll',
            'FivemDecryptFixer.Cli.deps.json','FivemDecryptFixer.Cli.runtimeconfig.json',
            'FivemDecryptFixer.dll','CodeWalker.Core.dll','SharpDX.dll','SharpDX.Mathematics.dll'
        )
        $missing = @($required | Where-Object {
            -not (Test-Path -LiteralPath (Join-Path $Context.Paths.ModelRepairDir $_) -PathType Leaf)
        })
        $version = ''
        $versionPath = Join-Path $Context.Paths.FxapDecryptorDir 'VERSION'
        if (Test-Path -LiteralPath $versionPath -PathType Leaf) {
            try { $version = [IO.File]::ReadAllText($versionPath).Trim() } catch { }
        }
        return [pscustomobject]@{
            Ok = ($missing.Count -eq 0)
            Missing = $missing
            Version = $version
        }
    }

    function Update-ModelRepairStartState {
        $targetExists = $false
        try { $targetExists = Test-Path -LiteralPath $ui.TargetBox.Text.Trim() -PathType Container } catch { }
        $ui.OpenFolderButton.IsEnabled = $targetExists
        $ui.StartButton.IsEnabled = (-not $state.Process) -and $state.Ready -and $targetExists
    }

    function Update-ModelRepairEnvironment {
        $component = & $getComponentInfoAction
        $dotnet = Get-CkDotNet8Info
        $state.Ready = [bool]$component.Ok -and [bool]$dotnet.Ok

        Set-CkStatusDot $ui.DotNetDot ([bool]$dotnet.Ok)
        Set-CkStatusDot $ui.ComponentDot ([bool]$component.Ok)
        $ui.DotNetText.Text = [string]$dotnet.Label
        $ui.DotNetText.ToolTip = if ($dotnet.Path) { [string]$dotnet.Path } else { [string]$dotnet.Label }
        $ui.DotNetButton.Visibility = if ($dotnet.Ok) { 'Collapsed' } else { 'Visible' }
        $ui.ComponentText.Text = if ($component.Ok) {
            if ($component.Version) { "已就绪 · $($component.Version)" } else { '已就绪' }
        } else { '请在顶部安装或更新组件' }
        $ui.ComponentText.ToolTip = if ($component.Ok) { [string]$Context.Paths.ModelRepairDir } else { "缺少: $($component.Missing -join ', ')" }
        $ui.EnvironmentStatus.Text = if ($state.Ready) { '运行环境就绪' } else { '请处理缺失项' }
        $ui.EnvironmentStatus.Foreground = if ($state.Ready) { (Get-CkThemeBrush '#31D69A') } else { (Get-CkThemeBrush '#EF7C86') }
        & $updateStartStateAction
    }

    function Set-ModelRepairRunning {
        param([bool]$Running)
        foreach ($control in @($ui.TargetBox,$ui.ChooseFolderButton,$ui.StartButton,$ui.DotNetButton)) {
            $control.IsEnabled = -not $Running
        }
        $ui.OpenFolderButton.IsEnabled = (-not $Running) -and (Test-Path -LiteralPath $ui.TargetBox.Text.Trim() -PathType Container)
        $ui.StopButton.IsEnabled = $Running
        if ($Running) {
            $ui.ResultStatus.Text = '正在修复'
            $ui.ResultStatus.Foreground = (Get-CkThemeBrush '#72B7F2')
            $ui.StatusLine.Text = '正在递归扫描并修复模型，可随时停止。'
            $ui.ProgressBar.Value = 2
        } else {
            & $updateStartStateAction
        }
    }

    function Reset-ModelRepairStatistics {
        $state.Total = 0
        $state.Current = 0
        $state.Scanned = 0
        $state.Repaired = 0
        $state.Skipped = 0
        $state.Failed = 0
        $state.SummarySeen = $false
        $ui.ScannedCount.Text = '0'
        $ui.RepairedCount.Text = '0'
        $ui.SkippedCount.Text = '0'
        $ui.FailedCount.Text = '0'
        $ui.ProgressBar.Value = 0
    }

    function Update-ModelRepairProgressFromLine {
        param([string]$Line)
        [void]$state.Output.AppendLine([string]$Line)
        Add-CkLogLine -TextBox $ui.LogBox -Line ([string]$Line)

        $outputEvent = & $updateOutputStateAction -State $state -Line $Line
        switch ($outputEvent.Kind) {
        'native-log' {
            $ui.OpenNativeLogButton.IsEnabled = Test-Path -LiteralPath $state.NativeLogPath -PathType Leaf
        }
        'progress' {
            $ui.ScannedCount.Text = [string]$state.Scanned
            $ui.ProgressBar.Value = [Math]::Min(96, [Math]::Max(2, [Math]::Floor(($state.Current / $state.Total) * 96)))
            $ui.StatusLine.Text = "正在处理 $($state.Current)/$($state.Total)：$($outputEvent.Path)"
        }
        'repaired' {
            $ui.RepairedCount.Text = [string]$state.Repaired
        }
        'skipped' {
            $ui.SkippedCount.Text = [string]$state.Skipped
        }
        'failed' {
            $ui.FailedCount.Text = [string]$state.Failed
        }
        'skipped-summary' {
            $ui.SkippedCount.Text = [string]$state.Skipped
        }
        'summary' {
            $ui.ScannedCount.Text = [string]$state.Scanned
            $ui.RepairedCount.Text = [string]$state.Repaired
            $ui.SkippedCount.Text = [string]$state.Skipped
            $ui.FailedCount.Text = [string]$state.Failed
            $ui.ProgressBar.Value = 99
            $ui.StatusLine.Text = "扫描 $($state.Scanned)，修复 $($state.Repaired)，无需修复 $($state.Skipped)，失败 $($state.Failed)"
        }
        'fatal' {
            $ui.StatusLine.Text = [string]$outputEvent.Message
        }
        }
    }

    function Save-ModelRepairReport {
        param([Parameter(Mandatory)][string]$Status, [int]$ExitCode)
        $finishedAt = Get-Date
        $startedAt = if ($state.StartedAt) { [datetime]$state.StartedAt } else { $finishedAt }
        $runName = (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 6)
        $runDir = Join-Path $state.ReportRoot $runName
        New-Item -ItemType Directory -Force -Path $runDir | Out-Null
        $logLines = @($state.Output.ToString().TrimEnd() -split '\r?\n')
        $payload = [ordered]@{
            schemaVersion = 1
            tool = 'model-repair'
            status = $Status
            exitCode = $ExitCode
            startedAt = $startedAt.ToString('o')
            finishedAt = $finishedAt.ToString('o')
            durationSeconds = [Math]::Round([Math]::Max(0, ($finishedAt - $startedAt).TotalSeconds), 3)
            target = [string]$state.TargetPath
            nativeLog = [string]$state.NativeLogPath
            summary = [ordered]@{
                scanned = [int]$state.Scanned
                repaired = [int]$state.Repaired
                skipped = [int]$state.Skipped
                failed = [int]$state.Failed
            }
            log = $logLines
        }
        $jsonPath = Join-Path $runDir 'report.json'
        [IO.File]::WriteAllText($jsonPath, ($payload | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))

        $markdown = New-Object System.Collections.Generic.List[string]
        $markdown.Add('# 模型修复报告')
        $markdown.Add('')
        $markdown.Add("- 状态: $Status")
        $markdown.Add("- 退出码: $ExitCode")
        $markdown.Add("- 开始时间: $($startedAt.ToString('yyyy-MM-dd HH:mm:ss'))")
        $markdown.Add("- 结束时间: $($finishedAt.ToString('yyyy-MM-dd HH:mm:ss'))")
        $markdown.Add("- 目标目录: $($state.TargetPath)")
        $markdown.Add("- 原生日志: $($state.NativeLogPath)")
        $markdown.Add('')
        $markdown.Add('## 统计')
        $markdown.Add('')
        $markdown.Add('| 扫描 | 修复 | 无需修复 | 失败 |')
        $markdown.Add('| ---: | ---: | ---: | ---: |')
        $markdown.Add("| $($state.Scanned) | $($state.Repaired) | $($state.Skipped) | $($state.Failed) |")
        $markdown.Add('')
        $markdown.Add('## 日志')
        $markdown.Add('')
        $markdown.Add('~~~text')
        foreach ($line in $logLines) { $markdown.Add([string]$line) }
        $markdown.Add('~~~')
        $markdownPath = Join-Path $runDir 'report.md'
        [IO.File]::WriteAllText($markdownPath, ($markdown -join [Environment]::NewLine), (New-Object Text.UTF8Encoding($false)))
        return [pscustomobject]@{ Markdown = [IO.Path]::GetFullPath($markdownPath); Json = [IO.Path]::GetFullPath($jsonPath) }
    }

    $updateOutputStateAction = (Get-Command Update-CkModelRepairOutputState).ScriptBlock.GetNewClosure()
    $resolveResultAction = (Get-Command Resolve-CkModelRepairResult).ScriptBlock.GetNewClosure()
    $getComponentInfoAction = (Get-Command Get-ModelRepairComponentInfo).ScriptBlock.GetNewClosure()
    $updateStartStateAction = (Get-Command Update-ModelRepairStartState).ScriptBlock.GetNewClosure()
    $updateEnvironmentAction = (Get-Command Update-ModelRepairEnvironment).ScriptBlock.GetNewClosure()
    $setRunningAction = (Get-Command Set-ModelRepairRunning).ScriptBlock.GetNewClosure()
    $resetStatisticsAction = (Get-Command Reset-ModelRepairStatistics).ScriptBlock.GetNewClosure()
    $parseOutputAction = (Get-Command Update-ModelRepairProgressFromLine).ScriptBlock.GetNewClosure()
    $saveReportAction = (Get-Command Save-ModelRepairReport).ScriptBlock.GetNewClosure()

    $showPageError = {
        param([string]$Message)
        $ui.ResultStatus.Text = '操作失败'
        $ui.ResultStatus.Foreground = (Get-CkThemeBrush '#EF7C86')
        $ui.StatusLine.Text = $Message
        Add-CkLogLine -TextBox $ui.LogBox -Line "[工具箱] $Message"
        [System.Windows.MessageBox]::Show($Message, 'CK免费工具箱 - 模型修复') | Out-Null
    }.GetNewClosure()

    $openDotNetAction = { Start-Process -FilePath 'https://dotnet.microsoft.com/download/dotnet/8.0' }.GetNewClosure()
    $chooseFolderAction = {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = '选择包含 .ydr、.yft 或 .ydd 的目录'
        $dialog.ShowNewFolderButton = $false
        Set-CkDialogInitialPath -Dialog $dialog -Path $ui.TargetBox.Text
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $ui.TargetBox.Text = [IO.Path]::GetFullPath($dialog.SelectedPath)
            }
        } finally { $dialog.Dispose() }
    }.GetNewClosure()
    $openFolderAction = {
        $path = $ui.TargetBox.Text.Trim()
        if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Container)) { throw "目录不存在: $path" }
        Start-Process -FilePath explorer.exe -ArgumentList @([IO.Path]::GetFullPath($path))
    }.GetNewClosure()
    $openNativeLogAction = {
        $path = [string]$state.NativeLogPath
        if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { throw '本次原生日志不存在。' }
        Start-Process -FilePath notepad.exe -ArgumentList ('"{0}"' -f $path) -ErrorAction Stop
    }.GetNewClosure()
    $openReportAction = {
        $path = [string]$state.ReportPath
        if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { throw '本次模型修复报告不存在。' }
        Start-Process -FilePath notepad.exe -ArgumentList ('"{0}"' -f $path) -ErrorAction Stop
    }.GetNewClosure()
    $openReportHistoryAction = {
        if (-not (Test-Path -LiteralPath $state.ReportRoot -PathType Container)) { New-Item -ItemType Directory -Force -Path $state.ReportRoot | Out-Null }
        Start-Process -FilePath explorer.exe -ArgumentList @($state.ReportRoot)
    }.GetNewClosure()

    $startAction = {
        if ($state.Process -and -not $state.Process.Process.HasExited) { throw '已有模型修复任务正在运行。' }
        & $updateEnvironmentAction
        if (-not $state.Ready) { throw '模型修复运行环境未就绪，请先处理页面顶部的缺失项。' }
        $target = $ui.TargetBox.Text.Trim()
        if (-not $target -or -not (Test-Path -LiteralPath $target -PathType Container)) { throw "模型目录不存在: $target" }
        $target = [IO.Path]::GetFullPath($target).TrimEnd('\')
        $driveRoot = [IO.Path]::GetPathRoot($target).TrimEnd('\')
        if ($target.Equals($driveRoot, [StringComparison]::OrdinalIgnoreCase)) { throw '不能把整个磁盘作为模型修复目录。' }

        $answer = [System.Windows.MessageBox]::Show(
            "模型修复会原地修改成功处理的 .ydr、.yft、.ydd 文件。`n失败模型保持原样，重要资源仍建议先备份。`n`n目标: $target`n`n是否继续？",
            '确认开始模型修复',
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )
        if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }

        $state.CancelRequested = $false
        $state.StartedAt = Get-Date
        $state.TargetPath = $target
        $state.NativeLogPath = ''
        $state.ReportPath = ''
        $state.JsonReportPath = ''
        $state.Output = New-Object Text.StringBuilder
        & $resetStatisticsAction
        $ui.OpenNativeLogButton.IsEnabled = $false
        $ui.OpenReportButton.IsEnabled = $false
        $ui.LogBox.Clear()
        Add-CkLogLine -TextBox $ui.LogBox -Line "[工具箱] 目标目录: $target"
        Add-CkLogLine -TextBox $ui.LogBox -Line '[工具箱] 成功模型将原地原子替换；失败模型不会修改。'
        [void]$state.Output.AppendLine("[工具箱] 目标目录: $target")
        [void]$state.Output.AppendLine('[工具箱] 成功模型将原地原子替换；失败模型不会修改。')
        & $setRunningAction $true

        $callbackState = $state
        $callbackUi = $ui
        $callbackParse = $parseOutputAction
        $callbackSetRunning = $setRunningAction
        $callbackSaveReport = $saveReportAction
        $callbackUpdateEnvironment = $updateEnvironmentAction
        $callbackResolveResult = $resolveResultAction
        $onOutput = { param($Line) & $callbackParse ([string]$Line) }.GetNewClosure()
        $onProcessError = { param($Message) $callbackUi.StatusLine.Text = [string]$Message }.GetNewClosure()
        $onExit = {
            param($ExitCode)
            $cancelled = $callbackState.CancelRequested
            $callbackState.CancelRequested = $false
            $callbackState.Process = $null
            & $callbackSetRunning $false

            $result = & $callbackResolveResult -ExitCode $ExitCode -Cancelled $cancelled `
                -Scanned $callbackState.Scanned -Repaired $callbackState.Repaired `
                -Skipped $callbackState.Skipped -Failed $callbackState.Failed
            $reportStatus = [string]$result.Status
            if ($null -ne $result.Progress) { $callbackUi.ProgressBar.Value = [double]$result.Progress }
            $callbackUi.ResultStatus.Text = [string]$result.ResultText
            $callbackUi.ResultStatus.Foreground = (Get-CkThemeBrush ([string]$result.Color))
            $callbackUi.StatusLine.Text = [string]$result.Message

            try {
                $report = & $callbackSaveReport -Status $reportStatus -ExitCode $ExitCode
                $callbackState.ReportPath = [string]$report.Markdown
                $callbackState.JsonReportPath = [string]$report.Json
                $callbackUi.OpenReportButton.IsEnabled = $true
                Add-CkLogLine -TextBox $callbackUi.LogBox -Line "[工具箱] 本次报告: $($callbackState.ReportPath)"
            } catch {
                Add-CkLogLine -TextBox $callbackUi.LogBox -Line "[工具箱] 报告保存失败: $($_.Exception.Message)"
            }
            & $callbackUpdateEnvironment
        }.GetNewClosure()

        try {
            $state.Process = Start-CkLoggedProcess -FileName $Context.Paths.ModelRepairExe -Arguments @('fix-models', $target) -WorkingDirectory $Context.Paths.ModelRepairDir -Dispatcher $Context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onProcessError
        } catch {
            & $setRunningAction $false
            throw
        }
    }.GetNewClosure()

    $stopAction = {
        if (-not $state.Process -or $state.Process.Process.HasExited) { return }
        $state.CancelRequested = $true
        $ui.StopButton.IsEnabled = $false
        $ui.ResultStatus.Text = '正在停止'
        $ui.StatusLine.Text = '正在停止模型修复进程...'
        $pidToStop = $state.Process.Process.Id
        try {
            $killerInfo = New-Object Diagnostics.ProcessStartInfo
            $killerInfo.FileName = 'taskkill.exe'
            $killerInfo.Arguments = "/PID $pidToStop /T /F"
            $killerInfo.UseShellExecute = $false
            $killerInfo.CreateNoWindow = $true
            $killer = [Diagnostics.Process]::Start($killerInfo)
            if ($killer) { [void]$killer.WaitForExit(5000); $killer.Dispose() }
            if (-not $state.Process.Process.HasExited) { $state.Process.Process.Kill() }
        } catch {
            $state.CancelRequested = $false
            throw "停止任务失败: $($_.Exception.Message)"
        }
    }.GetNewClosure()

    $targetChangedHandler = { & $updateStartStateAction }.GetNewClosure()
    $ui.TargetBox.Add_TextChanged($targetChangedHandler)
    Register-CkButtonAction -Button $ui.DotNetButton -Action $openDotNetAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseFolderButton -Action $chooseFolderAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenFolderButton -Action $openFolderAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenNativeLogButton -Action $openNativeLogAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenReportButton -Action $openReportAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenReportHistoryButton -Action $openReportHistoryAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StartButton -Action $startAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StopButton -Action $stopAction -OnError $showPageError

    & $updateEnvironmentAction
    return [pscustomobject]@{
        Id = 'model-repair'
        Title = '模型修复'
        Icon = '◈'
        Root = $root
        Activate = $updateEnvironmentAction
    }
}

function Update-CkModelRepairOutputState {
    param(
        [Parameter(Mandatory)]$State,
        [AllowEmptyString()][string]$Line
    )

    $event = [ordered]@{ Kind = 'log'; Path = ''; Message = '' }
    if ($Line -match '^\[MODEL LOG\]\s+(?<path>.+?)\s*$') {
        $State.NativeLogPath = [string]$Matches.path
        $event.Kind = 'native-log'
        $event.Path = [string]$Matches.path
    } elseif ($Line -match '^\[MODEL\s+(?<current>\d+)\/(?<total>\d+)\]\s+(?<path>.+)$') {
        $State.Current = [int]$Matches.current
        $State.Total = [Math]::Max(1, [int]$Matches.total)
        $State.Scanned = $State.Current
        $event.Kind = 'progress'
        $event.Path = [string]$Matches.path
    } elseif ($Line -match '^\[MODEL OK\]' -and -not $State.SummarySeen) {
        $State.Repaired++
        $event.Kind = 'repaired'
    } elseif ($Line -match '^\[MODEL SKIP\]' -and -not $State.SummarySeen) {
        $State.Skipped++
        $event.Kind = 'skipped'
    } elseif ($Line -match '^\[MODEL ERROR\]' -and -not $State.SummarySeen) {
        $State.Failed++
        $event.Kind = 'failed'
    } elseif ($Line -match '^\[MODEL SKIPPED\]\s+count=(?<count>\d+)') {
        $State.Skipped = [int]$Matches.count
        $event.Kind = 'skipped-summary'
    } elseif ($Line -match '^\[MODEL\]\s+scanned=(?<scanned>\d+),\s*repaired=(?<repaired>\d+),\s*failed=(?<failed>\d+)') {
        $State.SummarySeen = $true
        $State.Scanned = [int]$Matches.scanned
        $State.Repaired = [int]$Matches.repaired
        $State.Failed = [int]$Matches.failed
        $State.Skipped = [Math]::Max(0, $State.Scanned - $State.Repaired - $State.Failed)
        $event.Kind = 'summary'
    } elseif ($Line -match '^\[MODEL FATAL\]\s*(?<message>.*)$') {
        $event.Kind = 'fatal'
        $event.Message = if ($Matches.message) { [string]$Matches.message } else { '模型修复组件启动失败。' }
    }

    return [pscustomobject]$event
}

function Resolve-CkModelRepairResult {
    param(
        [int]$ExitCode,
        [bool]$Cancelled,
        [int]$Scanned,
        [int]$Repaired,
        [int]$Skipped,
        [int]$Failed
    )

    if ($Cancelled) {
        return [pscustomobject]@{
            Status = 'cancelled'; ResultText = '任务已停止'; Color = '#F4B860'; Progress = $null
            Message = '任务已停止；已经成功修复的模型不会自动回滚。'
        }
    }
    if ($Failed -gt 0) {
        if ($Scanned -gt 0 -or $Repaired -gt 0 -or $Skipped -gt 0) {
            return [pscustomobject]@{
                Status = 'partial'; ResultText = '完成，存在失败'; Color = '#F4B860'; Progress = 100
                Message = "已修复 $Repaired，失败 $Failed；失败模型保持原样。"
            }
        }
        return [pscustomobject]@{
            Status = 'failed'; ResultText = '修复失败'; Color = '#EF7C86'; Progress = 0
            Message = "模型修复失败 $Failed 项，退出码: $ExitCode，请查看日志。"
        }
    }
    if ($ExitCode -eq 0 -and $Scanned -eq 0) {
        return [pscustomobject]@{
            Status = 'empty'; ResultText = '未发现模型'; Color = '#F4B860'; Progress = 100
            Message = '目录中没有发现可处理的 .ydr、.yft 或 .ydd 文件。'
        }
    }
    if ($ExitCode -eq 0) {
        return [pscustomobject]@{
            Status = 'success'; ResultText = '修复完成'; Color = '#31D69A'; Progress = 100
            Message = "模型修复完成：修复 $Repaired，无需修复 $Skipped。"
        }
    }
    if ($ExitCode -eq 1 -and $Scanned -gt 0) {
        return [pscustomobject]@{
            Status = 'partial'; ResultText = '完成，存在失败'; Color = '#F4B860'; Progress = 100
            Message = "已扫描 $Scanned，修复 $Repaired，进程退出码为 1；请检查日志。"
        }
    }
    return [pscustomobject]@{
        Status = 'failed'; ResultText = '修复失败'; Color = '#EF7C86'; Progress = 0
        Message = "模型修复退出码: $ExitCode，请查看日志。"
    }
}
