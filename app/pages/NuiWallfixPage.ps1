function New-CkNuiWallfixPage {
    param([Parameter(Mandatory)]$Context)

    $reportRoot = Join-Path (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CKFreeToolbox') 'nui-wallfix-reports'
    $state = [pscustomobject]@{
        Process = $null
        TargetPath = $Context.Paths.DefaultWallfixInput
        LastOperation = ''
        CancelRequested = $false
        ReportRoot = $reportRoot
        ReportPath = ''
    }

    $xaml = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
              xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
              VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
  <ScrollViewer.Resources>
    <Style TargetType="ComboBox">
      <Setter Property="Foreground" Value="#111827"/>
      <Setter Property="Background" Value="#20242B"/>
      <Setter Property="BorderBrush" Value="#596273"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="9,6"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
    <Style TargetType="ComboBoxItem">
      <Setter Property="Foreground" Value="#F4F7FB"/>
      <Setter Property="Background" Value="#20242B"/>
      <Setter Property="Padding" Value="10,8"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#A4AAB4"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="VerticalAlignment" Value="Center"/>
    </Style>
  </ScrollViewer.Resources>

  <StackPanel Margin="22">
    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="18" Margin="0,0,0,14">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <StackPanel>
          <StackPanel Orientation="Horizontal">
            <Border Width="4" Height="22" CornerRadius="3" Background="#58A6FF" Margin="0,0,10,0"/>
            <TextBlock Text="NUI 自动去墙" FontSize="22" FontWeight="Bold"/>
          </StackPanel>
          <TextBlock Text="FiveM NUI 外链扫描、本地化与安全恢复" Foreground="#777B83" FontSize="13" Margin="14,6,0,0"/>
        </StackPanel>
        <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
          <Ellipse x:Name="EnvironmentDot" Width="10" Height="10" Fill="#31D69A" Margin="0,0,8,0"/>
          <TextBlock x:Name="EnvironmentText" AutomationProperties.AutomationId="NuiWallfix.EnvironmentText" Text="检测中" Foreground="#31D69A" FontWeight="SemiBold" Margin="0,0,10,0"/>
          <Button x:Name="PythonDownloadButton" AutomationProperties.AutomationId="NuiWallfix.PythonDownloadButton" Content="官网" Width="52" Height="28" Margin="0,0,6,0" Foreground="#58A6FF" Visibility="Collapsed" ToolTip="打开 Python 官方 Windows 下载页面"/>
          <Button x:Name="PythonBrowseButton" AutomationProperties.AutomationId="NuiWallfix.PythonBrowseButton" Content="选择" Width="52" Height="28" ToolTip="选择 Python 安装目录中的 python.exe"/>
        </StackPanel>
      </Grid>
    </Border>

    <Grid Margin="0,0,0,14">
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="96"/><ColumnDefinition Width="96"/></Grid.ColumnDefinitions>
      <StackPanel>
        <TextBlock Text="FiveM 资源目录" Foreground="#8B9099" FontSize="13" Margin="0,0,0,6"/>
        <TextBox x:Name="TargetBox" AutomationProperties.AutomationId="NuiWallfix.TargetBox" Height="38"/>
      </StackPanel>
      <Button x:Name="ChooseTargetButton" AutomationProperties.AutomationId="NuiWallfix.ChooseTargetButton" Grid.Column="1" Content="选择目录" Height="38" Margin="8,23,0,0" Background="#173055" Foreground="#58A6FF"/>
      <Button x:Name="OpenTargetButton" AutomationProperties.AutomationId="NuiWallfix.OpenTargetButton" Grid.Column="2" Content="打开目录" Height="38" Margin="8,23,0,0"/>
    </Grid>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="1.2*"/>
          <ColumnDefinition Width="0.7*"/>
          <ColumnDefinition Width="0.7*"/>
        </Grid.ColumnDefinitions>

        <StackPanel Grid.Row="0" Grid.Column="0" Margin="0,0,8,10">
          <TextBlock Text="处理方案" Foreground="#B8C0CC" FontSize="13" Margin="0,0,0,6"/>
          <ComboBox x:Name="ModeBox" AutomationProperties.AutomationId="NuiWallfix.ModeBox" Height="38">
            <ComboBoxItem Tag="auto" Content="自动方案（推荐）" AutomationProperties.Name="自动方案（推荐）"/>
            <ComboBoxItem Tag="local" Content="完全本地化" AutomationProperties.Name="完全本地化"/>
            <ComboBoxItem Tag="cn-cdn" Content="仅国内 CDN" AutomationProperties.Name="仅国内 CDN"/>
          </ComboBox>
        </StackPanel>
        <StackPanel Grid.Row="0" Grid.Column="1" Margin="8,0,8,10">
          <TextBlock Text="网络超时（秒）" Foreground="#8B9099" FontSize="13" Margin="0,0,0,6"/>
          <TextBox x:Name="TimeoutBox" AutomationProperties.AutomationId="NuiWallfix.TimeoutBox" Height="38" Text="15"/>
        </StackPanel>
        <StackPanel Grid.Row="0" Grid.Column="2" Margin="8,0,0,10">
          <TextBlock Text="单文件上限（MB）" Foreground="#8B9099" FontSize="13" Margin="0,0,0,6"/>
          <TextBox x:Name="MaxMbBox" AutomationProperties.AutomationId="NuiWallfix.MaxMbBox" Height="38" Text="20"/>
        </StackPanel>

        <StackPanel Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="2" Margin="0,0,8,10">
          <TextBlock Text="CDN 规则" Foreground="#8B9099" FontSize="13" Margin="0,0,0,6"/>
          <TextBox x:Name="ProvidersBox" AutomationProperties.AutomationId="NuiWallfix.ProvidersBox" Height="38"/>
        </StackPanel>
        <StackPanel Grid.Row="1" Grid.Column="2" Margin="8,0,0,10">
          <TextBlock Text="备份目录（可选）" Foreground="#8B9099" FontSize="13" Margin="0,0,0,6"/>
          <Grid>
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="68"/></Grid.ColumnDefinitions>
            <TextBox x:Name="StateDirBox" AutomationProperties.AutomationId="NuiWallfix.StateDirBox" Height="38"/>
            <Button x:Name="ChooseStateDirButton" Grid.Column="1" Content="选择" Height="38" Margin="6,0,0,0"/>
          </Grid>
        </StackPanel>

        <StackPanel Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="3" Orientation="Horizontal">
          <CheckBox x:Name="AllowUnverifiedBox" AutomationProperties.AutomationId="NuiWallfix.AllowUnverifiedBox" Content="允许未验证镜像" Margin="0,0,24,0"/>
          <CheckBox x:Name="AllowPrivateBox" AutomationProperties.AutomationId="NuiWallfix.AllowPrivateBox" Content="允许内网地址" Margin="0,0,24,0"/>
          <CheckBox x:Name="ForceRestoreBox" AutomationProperties.AutomationId="NuiWallfix.ForceRestoreBox" Content="恢复时覆盖冲突文件"/>
        </StackPanel>
      </Grid>
    </Border>

    <Grid Margin="0,0,0,14">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="0.72*"/>
      </Grid.ColumnDefinitions>
      <Button x:Name="ScanButton" AutomationProperties.AutomationId="NuiWallfix.ScanButton" Grid.Column="0" Content="安全扫描" Height="46" Margin="0,0,6,0"/>
      <Button x:Name="PreviewButton" AutomationProperties.AutomationId="NuiWallfix.PreviewButton" Grid.Column="1" Content="预览方案" Height="46" Margin="6,0" Background="#173055" Foreground="#58A6FF"/>
      <Button x:Name="ApplyButton" AutomationProperties.AutomationId="NuiWallfix.ApplyButton" Grid.Column="2" Content="执行自动去墙" Height="46" Margin="6,0" Background="#124834" Foreground="#54E0A9" FontWeight="Bold"/>
      <Button x:Name="CancelButton" AutomationProperties.AutomationId="NuiWallfix.CancelButton" Grid.Column="3" Content="停止任务" Height="46" Margin="6,0,0,0" Foreground="#F28B94" IsEnabled="False"/>
    </Grid>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="112"/><ColumnDefinition Width="112"/></Grid.ColumnDefinitions>
        <StackPanel>
          <TextBlock Text="恢复 Run ID" Foreground="#8B9099" FontSize="13" Margin="0,0,0,6"/>
          <TextBox x:Name="RunIdBox" AutomationProperties.AutomationId="NuiWallfix.RunIdBox" Height="38"/>
        </StackPanel>
        <Button x:Name="RestoreButton" AutomationProperties.AutomationId="NuiWallfix.RestoreButton" Grid.Column="1" Content="恢复备份" Height="38" Margin="8,23,0,0" Foreground="#EF9A9A"/>
        <Button x:Name="OpenBackupsButton" Grid.Column="2" Content="打开备份" Height="38" Margin="8,23,0,0"/>
      </Grid>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12">
          <TextBlock Text="处理结果" FontSize="20" FontWeight="Bold"/>
          <TextBlock x:Name="ResultStatus" AutomationProperties.AutomationId="NuiWallfix.ResultStatus" Text="等待任务" HorizontalAlignment="Right" Foreground="#777B83" FontSize="14"/>
        </Grid>
        <UniformGrid Columns="5" Margin="0,0,0,14">
          <Border Background="#15181C" CornerRadius="6" Padding="10" Margin="0,0,5,0"><StackPanel><TextBlock Text="资源" Foreground="#777B83"/><TextBlock x:Name="ResourceCount" Text="0" FontSize="20" FontWeight="Bold"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="10" Margin="5,0"><StackPanel><TextBlock Text="外链" Foreground="#777B83"/><TextBlock x:Name="ReferenceCount" Text="0" FontSize="20" FontWeight="Bold"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="10" Margin="5,0"><StackPanel><TextBlock Text="已处理" Foreground="#777B83"/><TextBlock x:Name="ResolvedCount" Text="0" FontSize="20" FontWeight="Bold" Foreground="#31D69A"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="10" Margin="5,0"><StackPanel><TextBlock Text="未解决" Foreground="#777B83"/><TextBlock x:Name="UnresolvedCount" Text="0" FontSize="20" FontWeight="Bold" Foreground="#F4B860"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="10" Margin="5,0,0,0"><StackPanel><TextBlock Text="写入文件" Foreground="#777B83"/><TextBlock x:Name="WrittenCount" Text="0" FontSize="20" FontWeight="Bold" Foreground="#58A6FF"/></StackPanel></Border>
        </UniformGrid>
        <ProgressBar x:Name="ProgressBar" Height="8" Minimum="0" Maximum="100" Value="0"/>
        <TextBlock x:Name="StatusLine" AutomationProperties.AutomationId="NuiWallfix.StatusLine" Text="选择目录后开始扫描。" Foreground="#8B9099" FontSize="14" Margin="0,10,0,0"/>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16">
      <StackPanel>
        <Grid Margin="0,0,0,10">
          <TextBlock Text="报告明细" FontSize="20" FontWeight="Bold"/>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
            <Button x:Name="OpenReportButton" AutomationProperties.AutomationId="NuiWallfix.OpenReportButton" Content="打开本次报告" Height="30" Margin="0,0,8,0" IsEnabled="False"/>
            <Button x:Name="OpenReportHistoryButton" AutomationProperties.AutomationId="NuiWallfix.OpenReportHistoryButton" Content="报告历史" Height="30"/>
          </StackPanel>
        </Grid>
        <TextBox x:Name="LogBox" AutomationProperties.AutomationId="NuiWallfix.LogBox" MinHeight="210" MaxHeight="420" AcceptsReturn="True" TextWrapping="NoWrap" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" IsReadOnly="True" Text="等待任务输出..."/>
      </StackPanel>
    </Border>
  </StackPanel>
</ScrollViewer>
"@

    $root = Import-CkXaml $xaml
    $ui = Get-CkNamedControls -Root $root -Names @(
        'EnvironmentDot','EnvironmentText','PythonDownloadButton','PythonBrowseButton','TargetBox','ChooseTargetButton','OpenTargetButton',
        'ModeBox','TimeoutBox','MaxMbBox','ProvidersBox','StateDirBox','ChooseStateDirButton',
        'AllowUnverifiedBox','AllowPrivateBox','ForceRestoreBox','ScanButton','PreviewButton','ApplyButton','CancelButton',
        'RunIdBox','RestoreButton','OpenBackupsButton','ResultStatus','ResourceCount','ReferenceCount',
        'ResolvedCount','UnresolvedCount','WrittenCount','ProgressBar','StatusLine','OpenReportButton','OpenReportHistoryButton','LogBox'
    )

    $ui.TargetBox.Text = $state.TargetPath
    $ui.ProvidersBox.Text = $Context.Paths.WallfixProviders
    $ui.ModeBox.SelectedIndex = 0

    function Get-WallfixPythonInfo {
        $environment = Get-CkToolboxEnvironment -Context $Context
        $blenderPath = if ($environment.Blender.Ok) { $environment.Blender.Path } else { '' }
        $settings = Get-CkDependencySettings
        return Get-CkPythonInfo -RuntimeRoot $Context.Paths.RuntimeRoot -BlenderExe $blenderPath -ConfiguredPath ([string]$settings.PythonPath)
    }

    function Get-WallfixPython {
        $info = & $getPythonInfoAction
        if (-not $info.Ok) { throw [string]$info.Reason }
        return [string]$info.Path
    }

    function Update-WallfixEnvironment {
        $scriptOk = Test-Path -LiteralPath $Context.Paths.WallfixScript -PathType Leaf
        $runtimeV12 = Join-Path $Context.Paths.WallfixDir 'nuiwallfix\runtime_v12.py'
        $reportingModule = Join-Path $Context.Paths.WallfixDir 'nuiwallfix\reporting.py'
        $reportRuntimeOk = (Test-Path -LiteralPath $runtimeV12 -PathType Leaf) -and (Test-Path -LiteralPath $reportingModule -PathType Leaf)
        $providersOk = Test-Path -LiteralPath $Context.Paths.WallfixProviders -PathType Leaf
        $pythonInfo = & $getPythonInfoAction
        $pythonOk = [bool]$pythonInfo.Ok

        $ok = $scriptOk -and $reportRuntimeOk -and $providersOk -and $pythonOk
        Set-CkStatusDot $ui.EnvironmentDot $ok
        $ui.EnvironmentText.Foreground = if ($ok) { '#31D69A' } else { '#EF6B73' }
        $ui.EnvironmentText.Text = if ($ok) { "运行环境就绪 · $($pythonInfo.Label)" } elseif (-not $scriptOk) { '缺少 nui-wallfix' } elseif (-not $reportRuntimeOk) { '组件版本过旧，请更新' } elseif (-not $pythonOk) { '缺少 Python 3.7+' } else { '缺少 CDN 规则' }
        $ui.EnvironmentText.ToolTip = if ($pythonOk) { [string]$pythonInfo.Path } else { [string]$pythonInfo.Reason }
        $ui.PythonDownloadButton.Visibility = if ($pythonOk) { 'Collapsed' } else { 'Visible' }
        $ui.PythonBrowseButton.Content = if ($pythonOk) { '更改' } else { '选择' }
    }

    function Set-WallfixRunning {
        param([bool]$Running, [string]$Label = '')
        foreach ($button in @($ui.ScanButton, $ui.PreviewButton, $ui.ApplyButton, $ui.RestoreButton, $ui.PythonDownloadButton, $ui.PythonBrowseButton)) {
            $button.IsEnabled = -not $Running
        }
        $ui.CancelButton.IsEnabled = $Running
        $ui.ProgressBar.IsIndeterminate = $Running
        if ($Running) {
            $ui.ResultStatus.Text = $Label
            $ui.StatusLine.Text = '正在处理，可随时停止任务。'
            $ui.ProgressBar.Value = 18
        } else {
            $ui.ProgressBar.IsIndeterminate = $false
        }
    }

    function Get-WallfixSummaryValue {
        param($Summary, [string]$Name)
        if ($Summary -and $Summary.PSObject.Properties[$Name]) {
            return [int]$Summary.$Name
        }
        return 0
    }

    function Show-WallfixResult {
        param($Payload, [int]$ExitCode)

        $summary = $Payload.summary
        $resources = & $getSummaryValueAction $summary 'resources'
        $references = & $getSummaryValueAction $summary 'references'
        $remote = & $getSummaryValueAction $summary 'remote'
        $local = & $getSummaryValueAction $summary 'local'
        $unresolved = & $getSummaryValueAction $summary 'unresolved'
        $written = & $getSummaryValueAction $summary 'written_files'
        if (-not $written) { $written = & $getSummaryValueAction $summary 'files' }

        $ui.ResourceCount.Text = [string]$resources
        $ui.ReferenceCount.Text = [string]$references
        $ui.ResolvedCount.Text = [string]($remote + $local)
        $ui.UnresolvedCount.Text = [string]$unresolved
        $ui.WrittenCount.Text = [string]$written
        $ui.ProgressBar.Value = if ($ExitCode -in @(0, 10)) { 100 } else { 94 }

        if ($Payload.run_id) {
            $ui.RunIdBox.Text = [string]$Payload.run_id
        }

        $reportInfo = $null
        if ($Payload -and $Payload.PSObject.Properties['execution_report']) {
            $reportInfo = $Payload.execution_report
        }
        $reportPath = ''
        if ($reportInfo) {
            if ($reportInfo.markdown) {
                $reportPath = [string]$reportInfo.markdown
            } elseif ($reportInfo.json) {
                $reportPath = [string]$reportInfo.json
            }
        }
        if ($reportPath -and (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
            $state.ReportPath = [IO.Path]::GetFullPath($reportPath)
            $ui.OpenReportButton.IsEnabled = $true
        } else {
            $state.ReportPath = ''
            $ui.OpenReportButton.IsEnabled = $false
        }

        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add("命令: $($Payload.command)")
        $statusText = if ($Payload.status) { [string]$Payload.status } elseif ($Payload.command -eq 'scan') { '扫描完成' } else { '完成' }
        $lines.Add("状态: $statusText")
        if ($Payload.mode) { $lines.Add("方案: $($Payload.mode)") }
        if ($Payload.run_id) { $lines.Add("Run ID: $($Payload.run_id)") }
        if ($Payload.state_dir) { $lines.Add("备份目录: $($Payload.state_dir)") }
        if ($state.ReportPath) { $lines.Add("本次报告: $($state.ReportPath)") }
        if ($Payload.PSObject.Properties['execution_report_error'] -and $Payload.execution_report_error) {
            $lines.Add("报告错误: $($Payload.execution_report_error)")
        }
        if ($Payload.error) { $lines.Add("错误: $($Payload.error)") }
        $lines.Add('')

        $actionLabels = @{
            remote = '国内 CDN'
            local = '本地化'
            unresolved = '未解决'
            report = '仅报告'
            'report-only' = '仅报告'
            unchanged = '保持不变'
        }
        foreach ($item in @($Payload.references | Select-Object -First 120)) {
            $action = [string]$item.action
            $label = if (-not $action) { '发现外链' } elseif ($actionLabels.ContainsKey($action)) { $actionLabels[$action] } else { $action }
            $location = if ($item.line) { "$($item.file):$($item.line)" } else { [string]$item.file }
            $detail = if ($item.replacement) { [string]$item.replacement } elseif ($item.resolution_reason) { [string]$item.resolution_reason } elseif ($item.reason) { [string]$item.reason } else { '' }
            $lines.Add("[$label] $location")
            $lines.Add("  $($item.url)")
            if ($detail) { $lines.Add("  -> $detail") }
        }
        foreach ($diagnostic in @($Payload.diagnostics)) {
            $lines.Add("[$($diagnostic.level)] $($diagnostic.message)")
        }
        if (@($Payload.references).Count -gt 120) {
            $lines.Add('')
            $lines.Add("仅显示前 120 条，完整结果共 $(@($Payload.references).Count) 条。")
        }

        $ui.LogBox.Text = $lines -join [Environment]::NewLine
        $ui.LogBox.ScrollToHome()

        if ($ExitCode -eq 0) {
            $ui.ResultStatus.Text = '处理完成'
            $ui.ResultStatus.Foreground = '#31D69A'
            $ui.StatusLine.Text = '任务已完成。'
        } elseif ($ExitCode -eq 10) {
            $ui.ResultStatus.Text = '完成，需人工检查'
            $ui.ResultStatus.Foreground = '#F4B860'
            $ui.StatusLine.Text = '存在未解决或仅报告项目，请检查报告明细。'
        } elseif ($ExitCode -eq 50) {
            $ui.ResultStatus.Text = '恢复冲突'
            $ui.ResultStatus.Foreground = '#EF6B73'
            $ui.StatusLine.Text = '文件在写入后发生变化，默认未覆盖。'
        } else {
            $ui.ResultStatus.Text = '处理失败'
            $ui.ResultStatus.Foreground = '#EF6B73'
            $ui.StatusLine.Text = if ($Payload.error) { [string]$Payload.error } else { "进程退出码: $ExitCode" }
        }
    }

    $getPythonInfoAction = (Get-Command Get-WallfixPythonInfo).ScriptBlock.GetNewClosure()
    $getPythonAction = (Get-Command Get-WallfixPython).ScriptBlock.GetNewClosure()
    $updateEnvironmentAction = (Get-Command Update-WallfixEnvironment).ScriptBlock.GetNewClosure()
    $setRunningAction = (Get-Command Set-WallfixRunning).ScriptBlock.GetNewClosure()
    $getSummaryValueAction = (Get-Command Get-WallfixSummaryValue).ScriptBlock.GetNewClosure()
    $showResultAction = (Get-Command Show-WallfixResult).ScriptBlock.GetNewClosure()

    $showPageError = {
        param([string]$message)
        $ui.ResultStatus.Text = '操作失败'
        $ui.ResultStatus.Foreground = '#EF6B73'
        $ui.StatusLine.Text = $message
        Add-CkLogLine -TextBox $ui.LogBox -Line "[工具箱] $message"
        [System.Windows.MessageBox]::Show($message, 'CK免费工具箱 - NUI 自动去墙') | Out-Null
    }.GetNewClosure()

    $openPythonDownloadAction = {
        Start-Process -FilePath 'https://www.python.org/downloads/windows/'
    }.GetNewClosure()

    $selectPythonAction = {
        $settings = Get-CkDependencySettings
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Title = '选择 Python 主程序 python.exe'
        $dialog.Filter = 'Python 主程序 (python.exe)|python.exe|可执行文件 (*.exe)|*.exe'
        $dialog.CheckFileExists = $true
        $dialog.Multiselect = $false
        $dialog.RestoreDirectory = $true
        if ($settings.PythonPath -and (Test-Path -LiteralPath ([string]$settings.PythonPath) -PathType Leaf)) {
            $dialog.InitialDirectory = Split-Path -Parent ([string]$settings.PythonPath)
            $dialog.FileName = [string]$settings.PythonPath
        } else {
            $detected = & $getPythonInfoAction
            if ($detected.Ok) {
                $dialog.InitialDirectory = Split-Path -Parent ([string]$detected.Path)
                $dialog.FileName = [string]$detected.Path
            }
        }

        $owner = [System.Windows.Window]::GetWindow($root)
        $accepted = if ($owner) { $dialog.ShowDialog($owner) } else { $dialog.ShowDialog() }
        if ($accepted -ne $true) { return }
        $selected = [IO.Path]::GetFullPath($dialog.FileName)
        if ([IO.Path]::GetFileName($selected) -ine 'python.exe') {
            throw '请选择 Python 安装目录中的 python.exe。'
        }
        $info = Test-CkPythonExecutable -Path $selected
        if (-not $info.Ok) { throw [string]$info.Reason }
        [void](Set-CkDependencyPath -Dependency Python -Path $selected)
        & $updateEnvironmentAction
        $newLine = [Environment]::NewLine
        $message = "已识别 $($info.Label)$newLine$newLine$selected$newLine$newLine配置已保存到：$newLine$($Context.Paths.UserConfig)"
        if ($owner) {
            [System.Windows.MessageBox]::Show($owner, $message, 'Python 设置完成', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        } else {
            [System.Windows.MessageBox]::Show($message, 'Python 设置完成', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        }
    }.GetNewClosure()

    $chooseTargetAction = {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = '选择 FiveM resource 或 resources 目录'
        $dialog.SelectedPath = $ui.TargetBox.Text
        $dialog.ShowNewFolderButton = $false
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $ui.TargetBox.Text = $dialog.SelectedPath
                $state.TargetPath = $dialog.SelectedPath
            }
        } finally {
            $dialog.Dispose()
        }
    }.GetNewClosure()

    $openTargetAction = {
        $path = $ui.TargetBox.Text.Trim()
        if (-not (Test-Path -LiteralPath $path -PathType Container)) { throw "目录不存在: $path" }
        Start-Process -FilePath explorer.exe -ArgumentList @($path)
    }.GetNewClosure()

    $chooseStateDirAction = {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = '选择 nui-wallfix 备份目录'
        $dialog.SelectedPath = $ui.StateDirBox.Text
        $dialog.ShowNewFolderButton = $true
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $ui.StateDirBox.Text = $dialog.SelectedPath
            }
        } finally {
            $dialog.Dispose()
        }
    }.GetNewClosure()

    $openBackupsAction = {
        $selected = $ui.StateDirBox.Text.Trim()
        if (-not $selected) {
            $target = $ui.TargetBox.Text.Trim()
            if (-not $target) { throw '请先选择资源目录。' }
            $selected = Join-Path (Split-Path -Parent ([IO.Path]::GetFullPath($target))) '.nui-wallfix-backups'
        }
        if (-not (Test-Path -LiteralPath $selected -PathType Container)) { throw "备份目录不存在: $selected" }
        Start-Process -FilePath explorer.exe -ArgumentList @($selected)
    }.GetNewClosure()

    $openReportAction = {
        $path = [string]$state.ReportPath
        if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw '本次 NUI 执行报告不存在，请先完成一次操作。'
        }
        Start-Process -FilePath notepad.exe -ArgumentList @("`"$path`"") -ErrorAction Stop
    }.GetNewClosure()

    $openReportHistoryAction = {
        $path = [string]$state.ReportRoot
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            New-Item -ItemType Directory -Force -Path $path | Out-Null
        }
        Start-Process -FilePath explorer.exe -ArgumentList @($path)
    }.GetNewClosure()

    function Start-WallfixOperation {
        param([ValidateSet('scan','preview','apply','restore')][string]$Operation)

        if ($state.Process -and -not $state.Process.Process.HasExited) {
            throw '已有去墙任务正在运行。'
        }
        if (-not (Test-Path -LiteralPath $Context.Paths.WallfixScript -PathType Leaf)) {
            throw "nui-wallfix 入口不存在: $($Context.Paths.WallfixScript)"
        }
        $runtimeV12 = Join-Path $Context.Paths.WallfixDir 'nuiwallfix\runtime_v12.py'
        $reportingModule = Join-Path $Context.Paths.WallfixDir 'nuiwallfix\reporting.py'
        if (
            -not (Test-Path -LiteralPath $runtimeV12 -PathType Leaf) -or
            -not (Test-Path -LiteralPath $reportingModule -PathType Leaf)
        ) {
            throw '当前 NUI 组件版本不支持执行报告，请先在顶部更新组件。'
        }

        $target = $ui.TargetBox.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($target) -or -not (Test-Path -LiteralPath $target -PathType Container)) {
            throw '请先选择具体的 FiveM resource 或 resources 目录。'
        }
        $fullTarget = [IO.Path]::GetFullPath($target).TrimEnd('\')
        $driveRoot = [IO.Path]::GetPathRoot($fullTarget).TrimEnd('\')
        $workspaceRoot = [IO.Path]::GetFullPath($Context.Paths.WorkspaceRoot).TrimEnd('\')
        if ($fullTarget.Equals($driveRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw '不能扫描整个磁盘，请选择具体的 resource 或 resources 目录。'
        }
        if ($fullTarget.Equals($workspaceRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw '不能扫描工具箱工作区，请选择具体的 resource 或 resources 目录。'
        }
        $target = $fullTarget
        $state.TargetPath = $target

        $python = & $getPythonAction
        $args = @('-u', $Context.Paths.WallfixScript)
        $label = ''
        if ($Operation -eq 'scan') {
            $args += @('scan', $target, '--json')
            $label = '正在安全扫描'
        } elseif ($Operation -in @('preview','apply')) {
            $selectedMode = [string]$ui.ModeBox.SelectedItem.Tag
            $timeout = [double]::Parse($ui.TimeoutBox.Text.Trim(), [Globalization.CultureInfo]::InvariantCulture)
            $maxMb = [int]::Parse($ui.MaxMbBox.Text.Trim(), [Globalization.CultureInfo]::InvariantCulture)
            if ($timeout -le 0 -or $timeout -gt 300) { throw '网络超时必须在 0 到 300 秒之间。' }
            if ($maxMb -le 0 -or $maxMb -gt 1024) { throw '单文件上限必须在 1 到 1024 MB 之间。' }

            if ($Operation -eq 'apply') {
                $answer = [System.Windows.MessageBox]::Show(
                    "即将修改目录中的 NUI 文件：`n$target`n`n工具会在目标目录外创建备份。是否继续？",
                    '确认执行自动去墙',
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Warning
                )
                if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
            }

            $args += @('apply', $target, '--mode', $selectedMode, '--timeout', [string]$timeout, '--max-bytes', [string]($maxMb * 1MB))
            $providers = $ui.ProvidersBox.Text.Trim()
            if ($providers) {
                if (-not (Test-Path -LiteralPath $providers -PathType Leaf)) { throw "CDN 规则不存在: $providers" }
                $args += @('--providers', $providers)
            }
            $stateDir = $ui.StateDirBox.Text.Trim()
            if ($stateDir) { $args += @('--state-dir', $stateDir) }
            if ($ui.AllowUnverifiedBox.IsChecked) { $args += '--allow-unverified-mirror' }
            if ($ui.AllowPrivateBox.IsChecked) { $args += '--allow-private-network' }
            if ($Operation -eq 'apply') { $args += '--write' }
            $args += '--json'
            $label = if ($Operation -eq 'apply') { '正在执行自动去墙' } else { '正在生成预览方案' }
        } else {
            $runId = $ui.RunIdBox.Text.Trim()
            if (-not $runId) { throw '请输入需要恢复的 Run ID。' }
            $answer = [System.Windows.MessageBox]::Show(
                "即将恢复 Run ID：$runId`n目标目录：$target`n`n是否继续？",
                '确认恢复备份',
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }

            $args += @('restore', $target, '--run-id', $runId)
            $stateDir = $ui.StateDirBox.Text.Trim()
            if ($stateDir) { $args += @('--state-dir', $stateDir) }
            if ($ui.ForceRestoreBox.IsChecked) { $args += '--force' }
            $args += '--json'
            $label = '正在恢复备份'
        }

        $operationReportRoot = Join-Path $state.ReportRoot ('ck-toolbox-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 6))
        $args += @('--report-dir', $operationReportRoot)
        $state.LastOperation = $Operation
        $state.CancelRequested = $false
        $state.ReportPath = ''
        $ui.OpenReportButton.IsEnabled = $false
        $ui.LogBox.Text = ''
        $ui.ProgressBar.Value = 0
        & $setRunningAction $true $label

        $output = New-Object Text.StringBuilder
        $callbackOutput = $output
        $callbackState = $state
        $callbackUi = $ui
        $callbackShowResult = $showResultAction
        $callbackSetRunning = $setRunningAction

        $callbackOperationReportRoot = $operationReportRoot
        $onOutput = {
            param($line)
            [void]$callbackOutput.AppendLine($line)
            $callbackUi.ProgressBar.Value = [Math]::Min(86, $callbackUi.ProgressBar.Value + 4)
        }.GetNewClosure()

        $onProcessError = {
            param($message)
            $callbackUi.StatusLine.Text = $message
        }.GetNewClosure()

        $onExit = {
            param($exitCode)
            $wasCancelled = $callbackState.CancelRequested
            $callbackState.CancelRequested = $false
            $callbackState.Process = $null
            & $callbackSetRunning $false

            $raw = $callbackOutput.ToString().Trim()
            $payload = $null
            try {
                if ($raw) { $payload = $raw | ConvertFrom-Json }
            } catch { }
            if (-not $payload) {
                $lines = @($raw -split '\r?\n')
                for ($i = $lines.Count - 1; $i -ge 0 -and -not $payload; $i--) {
                    try { $payload = $lines[$i] | ConvertFrom-Json } catch { }
                }
            }
            if (-not $payload -and (Test-Path -LiteralPath $callbackOperationReportRoot -PathType Container)) {
                $historyJson = Get-ChildItem -LiteralPath $callbackOperationReportRoot -Filter 'report.json' -File -Recurse -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTimeUtc -Descending |
                    Select-Object -First 1
                if ($historyJson) {
                    try {
                        $reportDocument = Get-Content -LiteralPath $historyJson.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                        if ($reportDocument.PSObject.Properties['native_payload']) {
                            $payload = $reportDocument.native_payload
                        } else {
                            $historyMarkdown = Join-Path $historyJson.Directory.FullName 'report.md'
                            $callbackState.ReportPath = if (Test-Path -LiteralPath $historyMarkdown -PathType Leaf) { $historyMarkdown } else { $historyJson.FullName }
                            $callbackUi.OpenReportButton.IsEnabled = $true
                        }
                    } catch { }
                }
            }

            if ($payload) {
                & $callbackShowResult $payload $exitCode
            } else {
                $callbackUi.ProgressBar.Value = 94
                $callbackUi.ResultStatus.Text = '结果解析失败'
                $callbackUi.ResultStatus.Foreground = '#EF6B73'
                $callbackUi.StatusLine.Text = "进程退出码: $exitCode"
                $callbackUi.LogBox.Text = if ($raw) { $raw } else { 'nui-wallfix 没有返回结果。' }
            }

            if ($wasCancelled) {
                $callbackUi.ProgressBar.Value = 0
                $callbackUi.ResultStatus.Text = '任务已停止'
                $callbackUi.ResultStatus.Foreground = '#F4B860'
                if ($callbackState.ReportPath) {
                    $callbackUi.StatusLine.Text = '任务已停止；已保留停止前组件写出的本次报告。'
                    Add-CkLogLine -TextBox $callbackUi.LogBox -Line "本次报告: $($callbackState.ReportPath)"
                } else {
                    $callbackUi.StatusLine.Text = '任务已停止；组件尚未写出可用报告。'
                    $callbackUi.LogBox.Text = if ($raw) { $raw } else { '任务已由用户停止，组件尚未生成报告。' }
                }
            }
        }.GetNewClosure()

        try {
            $state.Process = Start-CkLoggedProcess -FileName $python -Arguments $args -WorkingDirectory $Context.Paths.WallfixDir -Dispatcher $Context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onProcessError
        } catch {
            & $setRunningAction $false
            throw
        }
    }

    $startOperationAction = (Get-Command Start-WallfixOperation).ScriptBlock.GetNewClosure()
    $scanAction = { & $startOperationAction 'scan' }.GetNewClosure()
    $previewAction = { & $startOperationAction 'preview' }.GetNewClosure()
    $applyAction = {
        $ui.ResultStatus.Text = '等待确认'
        & $startOperationAction 'apply'
    }.GetNewClosure()
    $restoreAction = {
        $ui.ResultStatus.Text = '等待确认'
        & $startOperationAction 'restore'
    }.GetNewClosure()
    $cancelAction = {
        if (-not $state.Process -or $state.Process.Process.HasExited) { return }
        $state.CancelRequested = $true
        $ui.CancelButton.IsEnabled = $false
        $ui.ResultStatus.Text = '正在停止'
        $ui.ResultStatus.Foreground = '#F4B860'
        $ui.StatusLine.Text = '正在停止当前任务...'
        try {
            $state.Process.Process.Kill()
        } catch {
            $state.CancelRequested = $false
            throw "停止任务失败: $($_.Exception.Message)"
        }
    }.GetNewClosure()

    Register-CkButtonAction -Button $ui.PythonDownloadButton -Action $openPythonDownloadAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.PythonBrowseButton -Action $selectPythonAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseTargetButton -Action $chooseTargetAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenTargetButton -Action $openTargetAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseStateDirButton -Action $chooseStateDirAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenBackupsButton -Action $openBackupsAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenReportButton -Action $openReportAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenReportHistoryButton -Action $openReportHistoryAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ScanButton -Action $scanAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.PreviewButton -Action $previewAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ApplyButton -Action $applyAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.CancelButton -Action $cancelAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.RestoreButton -Action $restoreAction -OnError $showPageError

    & $updateEnvironmentAction

    return [pscustomobject]@{
        Id = 'nui-wallfix'
        Title = 'NUI 自动去墙'
        Icon = '▥'
        Root = $root
        Activate = $updateEnvironmentAction
    }
}
