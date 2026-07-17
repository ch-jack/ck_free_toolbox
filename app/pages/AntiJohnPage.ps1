function New-CkAntiJohnPage {
    param([Parameter(Mandatory)]$Context)

    $state = [pscustomobject]@{
        Process = $null
        TargetPath = ''
        LastOperation = ''
        CancelRequested = $false
    }

    $xaml = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
              xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
              VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
  <ScrollViewer.Resources>
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
            <Border Width="4" Height="22" CornerRadius="3" Background="#EF6B73" Margin="0,0,10,0"/>
            <TextBlock Text="扫描移除后门" FontSize="22" FontWeight="Bold"/>
          </StackPanel>
          <TextBlock Text="FiveM resource / ZIP 后门静态扫描、自动移除与安全恢复" Foreground="#777B83" FontSize="13" Margin="14,6,0,0"/>
        </StackPanel>
        <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
          <Ellipse x:Name="EnvironmentDot" Width="10" Height="10" Fill="#31D69A" Margin="0,0,8,0"/>
          <TextBlock x:Name="EnvironmentText" AutomationProperties.AutomationId="AntiJohn.EnvironmentText" Text="检测中" Foreground="#31D69A" FontWeight="SemiBold" Margin="0,0,10,0"/>
          <Button x:Name="PythonDownloadButton" AutomationProperties.AutomationId="AntiJohn.PythonDownloadButton" Content="官网" Width="52" Height="28" Margin="0,0,6,0" Foreground="#58A6FF" Visibility="Collapsed" ToolTip="打开 Python 官方 Windows 下载页面"/>
          <Button x:Name="PythonBrowseButton" AutomationProperties.AutomationId="AntiJohn.PythonBrowseButton" Content="选择" Width="52" Height="28" ToolTip="选择 Python 安装目录中的 python.exe"/>
        </StackPanel>
      </Grid>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="扫描目标" Foreground="#B8C0CC" FontSize="13" Margin="0,0,0,6"/>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/><ColumnDefinition Width="92"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions>
          <TextBox x:Name="TargetBox" AutomationProperties.AutomationId="AntiJohn.TargetBox" Height="38"/>
          <Button x:Name="ChooseFolderButton" AutomationProperties.AutomationId="AntiJohn.ChooseFolderButton" Grid.Column="1" Content="选择目录" Height="38" Margin="8,0,0,0" Background="#173055" Foreground="#58A6FF"/>
          <Button x:Name="ChooseZipButton" AutomationProperties.AutomationId="AntiJohn.ChooseZipButton" Grid.Column="2" Content="选择 ZIP" Height="38" Margin="8,0,0,0" Background="#173055" Foreground="#58A6FF"/>
          <Button x:Name="OpenTargetButton" Grid.Column="3" Content="打开位置" Height="38" Margin="8,0,0,0"/>
        </Grid>
        <TextBlock Text="可选择单个 resource、resources 父目录或 ZIP；扫描不会联网，也不会执行目标中的代码。" Foreground="#6E7580" FontSize="12" Margin="0,8,0,0"/>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="0.35*"/><ColumnDefinition Width="1.2*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" Margin="0,0,8,0">
          <TextBlock Text="单文件扫描上限（MB）" Foreground="#8B9099" FontSize="13" Margin="0,0,0,6"/>
          <TextBox x:Name="MaxMbBox" AutomationProperties.AutomationId="AntiJohn.MaxMbBox" Height="38" Text="16"/>
        </StackPanel>
        <StackPanel Grid.Column="1" Margin="8,0">
          <TextBlock Text="备份目录（可选，必须位于目标外）" Foreground="#8B9099" FontSize="13" Margin="0,0,0,6"/>
          <Grid>
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="72"/></Grid.ColumnDefinitions>
            <TextBox x:Name="StateDirBox" AutomationProperties.AutomationId="AntiJohn.StateDirBox" Height="38"/>
            <Button x:Name="ChooseStateDirButton" Grid.Column="1" Content="选择" Height="38" Margin="6,0,0,0"/>
          </Grid>
        </StackPanel>
        <CheckBox x:Name="ForceRestoreBox" AutomationProperties.AutomationId="AntiJohn.ForceRestoreBox" Grid.Column="2" Content="恢复时覆盖冲突" Margin="18,23,0,0"/>
      </Grid>
    </Border>

    <Grid Margin="0,0,0,14">
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="0.72*"/></Grid.ColumnDefinitions>
      <Button x:Name="ScanButton" AutomationProperties.AutomationId="AntiJohn.ScanButton" Grid.Column="0" Content="扫描后门" Height="46" Margin="0,0,6,0"/>
      <Button x:Name="PreviewButton" AutomationProperties.AutomationId="AntiJohn.PreviewButton" Grid.Column="1" Content="移除预览" Height="46" Margin="6,0" Background="#173055" Foreground="#58A6FF"/>
      <Button x:Name="ApplyButton" AutomationProperties.AutomationId="AntiJohn.ApplyButton" Grid.Column="2" Content="确认移除" Height="46" Margin="6,0" Background="#5A2026" Foreground="#FF9CA3" FontWeight="Bold"/>
      <Button x:Name="CancelButton" AutomationProperties.AutomationId="AntiJohn.CancelButton" Grid.Column="3" Content="停止任务" Height="46" Margin="6,0,0,0" Foreground="#F28B94" IsEnabled="False"/>
    </Grid>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="112"/><ColumnDefinition Width="112"/></Grid.ColumnDefinitions>
        <StackPanel>
          <TextBlock Text="恢复 Run ID" Foreground="#8B9099" FontSize="13" Margin="0,0,0,6"/>
          <TextBox x:Name="RunIdBox" AutomationProperties.AutomationId="AntiJohn.RunIdBox" Height="38"/>
        </StackPanel>
        <Button x:Name="RestoreButton" AutomationProperties.AutomationId="AntiJohn.RestoreButton" Grid.Column="1" Content="恢复备份" Height="38" Margin="8,23,0,0" Foreground="#EF9A9A"/>
        <Button x:Name="OpenBackupsButton" Grid.Column="2" Content="打开备份" Height="38" Margin="8,23,0,0"/>
      </Grid>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12">
          <TextBlock Text="检测结果" FontSize="20" FontWeight="Bold"/>
          <TextBlock x:Name="ResultStatus" AutomationProperties.AutomationId="AntiJohn.ResultStatus" Text="等待任务" HorizontalAlignment="Right" Foreground="#777B83" FontSize="14"/>
        </Grid>
        <UniformGrid Columns="5" Margin="0,0,0,14">
          <Border Background="#15181C" CornerRadius="6" Padding="10" Margin="0,0,5,0"><StackPanel><TextBlock Text="文件" Foreground="#777B83"/><TextBlock x:Name="FileCount" Text="0" FontSize="20" FontWeight="Bold"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="10" Margin="5,0"><StackPanel><TextBlock Text="资源" Foreground="#777B83"/><TextBlock x:Name="ResourceCount" Text="0" FontSize="20" FontWeight="Bold"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="10" Margin="5,0"><StackPanel><TextBlock Text="发现" Foreground="#777B83"/><TextBlock x:Name="FindingCount" Text="0" FontSize="20" FontWeight="Bold" Foreground="#F4B860"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="10" Margin="5,0"><StackPanel><TextBlock Text="高危" Foreground="#777B83"/><TextBlock x:Name="CriticalCount" Text="0" FontSize="20" FontWeight="Bold" Foreground="#EF6B73"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="10" Margin="5,0,0,0"><StackPanel><TextBlock Text="可修复 / 动作" Foreground="#777B83"/><TextBlock x:Name="RepairableCount" Text="0" FontSize="20" FontWeight="Bold" Foreground="#58A6FF"/></StackPanel></Border>
        </UniformGrid>
        <ProgressBar x:Name="ProgressBar" Height="8" Minimum="0" Maximum="100" Value="0"/>
        <TextBlock x:Name="StatusLine" AutomationProperties.AutomationId="AntiJohn.StatusLine" Text="选择目标后先执行后门扫描。" Foreground="#8B9099" FontSize="14" Margin="0,10,0,0"/>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16">
      <StackPanel>
        <TextBlock Text="报告明细" FontSize="20" FontWeight="Bold" Margin="0,0,0,10"/>
        <TextBox x:Name="LogBox" AutomationProperties.AutomationId="AntiJohn.LogBox" MinHeight="230" MaxHeight="460" AcceptsReturn="True" TextWrapping="NoWrap" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" IsReadOnly="True" Text="等待任务输出..."/>
      </StackPanel>
    </Border>
  </StackPanel>
</ScrollViewer>
"@

    $root = Import-CkXaml $xaml
    $ui = Get-CkNamedControls -Root $root -Names @(
        'EnvironmentDot','EnvironmentText','PythonDownloadButton','PythonBrowseButton','TargetBox','ChooseFolderButton',
        'ChooseZipButton','OpenTargetButton','MaxMbBox','StateDirBox','ChooseStateDirButton','ForceRestoreBox',
        'ScanButton','PreviewButton','ApplyButton','CancelButton','RunIdBox','RestoreButton','OpenBackupsButton',
        'ResultStatus','FileCount','ResourceCount','FindingCount','CriticalCount','RepairableCount','ProgressBar','StatusLine','LogBox'
    )

    function Get-AntiJohnPythonInfo {
        $environment = Get-CkToolboxEnvironment -Context $Context
        $blenderPath = if ($environment.Blender.Ok) { $environment.Blender.Path } else { '' }
        $settings = Get-CkDependencySettings
        return Get-CkPythonInfo -RuntimeRoot $Context.Paths.RuntimeRoot -BlenderExe $blenderPath -ConfiguredPath ([string]$settings.PythonPath)
    }

    function Get-AntiJohnPython {
        $info = & $getPythonInfoAction
        if (-not $info.Ok) { throw [string]$info.Reason }
        return [string]$info.Path
    }

    function Update-AntiJohnEnvironment {
        $scriptOk = Test-Path -LiteralPath $Context.Paths.AntiJohnScript -PathType Leaf
        $pythonInfo = & $getPythonInfoAction
        $pythonOk = [bool]$pythonInfo.Ok
        $ok = $scriptOk -and $pythonOk
        Set-CkStatusDot $ui.EnvironmentDot $ok
        $ui.EnvironmentText.Foreground = if ($ok) { '#31D69A' } else { '#EF6B73' }
        $ui.EnvironmentText.Text = if ($ok) { "运行环境就绪 · $($pythonInfo.Label)" } elseif (-not $scriptOk) { '缺少后门扫描组件' } else { '缺少 Python 3.7+' }
        $ui.EnvironmentText.ToolTip = if ($pythonOk) { [string]$pythonInfo.Path } else { [string]$pythonInfo.Reason }
        $ui.PythonDownloadButton.Visibility = if ($pythonOk) { 'Collapsed' } else { 'Visible' }
        $ui.PythonBrowseButton.Content = if ($pythonOk) { '更改' } else { '选择' }
    }

    function Set-AntiJohnRunning {
        param([bool]$Running, [string]$Label = '')
        foreach ($button in @(
            $ui.ScanButton,$ui.PreviewButton,$ui.ApplyButton,$ui.RestoreButton,$ui.PythonDownloadButton,
            $ui.PythonBrowseButton,$ui.ChooseFolderButton,$ui.ChooseZipButton
        )) {
            $button.IsEnabled = -not $Running
        }
        $ui.CancelButton.IsEnabled = $Running
        $ui.ProgressBar.IsIndeterminate = $Running
        if ($Running) {
            $ui.ResultStatus.Text = $Label
            $ui.ResultStatus.Foreground = '#58A6FF'
            $ui.StatusLine.Text = '正在进行纯静态处理，可随时停止任务。'
            $ui.ProgressBar.Value = 18
        } else {
            $ui.ProgressBar.IsIndeterminate = $false
        }
    }

    function Get-AntiJohnProperty {
        param($Object, [string]$Name, $Default = $null)
        if ($Object -and $Object.PSObject.Properties[$Name]) { return $Object.$Name }
        return $Default
    }

    function Get-AntiJohnInt {
        param($Object, [string]$Name)
        $value = & $getPropertyAction $Object $Name 0
        if ($null -eq $value) { return 0 }
        return [int]$value
    }

    function Show-AntiJohnResult {
        param($Payload, [int]$ExitCode)

        $summary = & $getPropertyAction $Payload 'summary' $null
        $result = & $getPropertyAction $Payload 'result' $null
        $beforeScan = & $getPropertyAction $result 'before_scan' $null
        $beforeStats = & $getPropertyAction $beforeScan 'stats' $null
        $files = & $getIntAction $summary 'files_scanned'
        $resources = & $getIntAction $summary 'resources'
        if (-not $files) { $files = & $getIntAction $beforeStats 'files_scanned' }
        if (-not $resources) { $resources = & $getIntAction $beforeStats 'resources' }
        $findings = & $getIntAction $summary 'findings'
        $critical = & $getIntAction $summary 'critical'
        $repairable = & $getIntAction $summary 'repairable'
        $planned = & $getIntAction $summary 'planned'
        if ($planned) { $repairable = $planned }

        $ui.FileCount.Text = [string]$files
        $ui.ResourceCount.Text = [string]$resources
        $ui.FindingCount.Text = [string]$findings
        $ui.CriticalCount.Text = [string]$critical
        $ui.RepairableCount.Text = [string]$repairable
        $ui.ProgressBar.Value = if ($ExitCode -in @(0, 10)) { 100 } else { 94 }

        $runId = [string](& $getPropertyAction $summary 'run_id' '')
        if ($runId) { $ui.RunIdBox.Text = $runId }

        $lines = New-Object System.Collections.Generic.List[string]
        $operation = [string](& $getPropertyAction $Payload 'operation' $state.LastOperation)
        $status = [string](& $getPropertyAction $Payload 'status' '')
        $verdict = [string](& $getPropertyAction $summary 'verdict' '')
        if (-not $verdict) { $verdict = [string](& $getPropertyAction $summary 'verdict_after' '') }
        $lines.Add("操作: $operation")
        if ($status) { $lines.Add("状态: $status") }
        if ($verdict) { $lines.Add("结论: $verdict") }
        $outputPath = [string](& $getPropertyAction $summary 'output_path' '')
        $backupPath = [string](& $getPropertyAction $summary 'backup_path' '')
        $reportPath = [string](& $getPropertyAction $summary 'report_path' '')
        if (-not $reportPath) { $reportPath = [string](& $getPropertyAction $result 'report_path' '') }
        if ($outputPath) { $lines.Add("输出: $outputPath") }
        if ($backupPath) { $lines.Add("备份: $backupPath") }
        if ($reportPath) { $lines.Add("清理报告: $reportPath") }
        if ($runId) { $lines.Add("Run ID: $runId") }
        $errorText = [string](& $getPropertyAction $Payload 'error' '')
        if ($errorText) { $lines.Add("错误: $errorText") }
        $lines.Add('')

        $findingItems = @(& $getPropertyAction $result 'findings' @())
        if (-not $findingItems.Count -and $beforeScan) {
            $findingItems = @(& $getPropertyAction $beforeScan 'findings' @())
        }
        foreach ($item in @($findingItems | Select-Object -First 120)) {
            $severity = [string](& $getPropertyAction $item 'severity' '')
            $ruleId = [string](& $getPropertyAction $item 'rule_id' '')
            $path = [string](& $getPropertyAction $item 'path' '')
            $message = [string](& $getPropertyAction $item 'message' '')
            $evidence = [string](& $getPropertyAction $item 'evidence' '')
            $lines.Add("[$severity] $ruleId · $path")
            if ($message) { $lines.Add("  $message") }
            if ($evidence) { $lines.Add("  证据: $evidence") }
        }

        $actions = @(& $getPropertyAction $result 'actions' @())
        foreach ($item in @($actions | Select-Object -First 120)) {
            $action = [string](& $getPropertyAction $item 'action' '')
            $path = [string](& $getPropertyAction $item 'path' '')
            $reason = [string](& $getPropertyAction $item 'reason' '')
            $lines.Add("[$action] $path")
            if ($reason) { $lines.Add("  $reason") }
        }
        foreach ($message in @(& $getPropertyAction $result 'messages' @())) {
            $lines.Add("[信息] $message")
        }
        foreach ($message in @(& $getPropertyAction $result 'errors' @())) {
            $lines.Add("[错误] $message")
        }
        if ($findingItems.Count -gt 120 -or $actions.Count -gt 120) {
            $lines.Add('')
            $lines.Add('界面仅显示前 120 条，完整结果保留在组件 JSON 中。')
        }
        $ui.LogBox.Text = $lines -join [Environment]::NewLine
        $ui.LogBox.ScrollToHome()

        if ($ExitCode -eq 0) {
            $ui.ResultStatus.Text = if ($operation -eq 'restore') { '恢复完成' } else { '处理完成' }
            $ui.ResultStatus.Foreground = '#31D69A'
            $ui.StatusLine.Text = if ($verdict -eq 'clean') { '未发现后门，或移除后复检为 clean。' } else { '任务已完成；请查看剩余人工项。' }
        } elseif ($ExitCode -eq 10) {
            $ui.ResultStatus.Text = if ($state.LastOperation -eq 'scan') { '发现风险' } else { '预览完成，等待确认' }
            $ui.ResultStatus.Foreground = '#F4B860'
            $ui.StatusLine.Text = if ($state.LastOperation -eq 'scan') { '发现可疑或已确认感染项，请查看明细。' } else { '当前仅生成预览，没有写入目标。' }
        } elseif ($ExitCode -eq 50) {
            $ui.ResultStatus.Text = '恢复冲突'
            $ui.ResultStatus.Foreground = '#EF6B73'
            $ui.StatusLine.Text = '移除后的文件又发生变化，默认拒绝覆盖。'
        } else {
            $ui.ResultStatus.Text = '处理失败'
            $ui.ResultStatus.Foreground = '#EF6B73'
            $ui.StatusLine.Text = if ($errorText) { $errorText } else { "进程退出码: $ExitCode" }
        }
    }

    $getPythonInfoAction = (Get-Command Get-AntiJohnPythonInfo).ScriptBlock.GetNewClosure()
    $getPythonAction = (Get-Command Get-AntiJohnPython).ScriptBlock.GetNewClosure()
    $updateEnvironmentAction = (Get-Command Update-AntiJohnEnvironment).ScriptBlock.GetNewClosure()
    $setRunningAction = (Get-Command Set-AntiJohnRunning).ScriptBlock.GetNewClosure()
    $getPropertyAction = (Get-Command Get-AntiJohnProperty).ScriptBlock.GetNewClosure()
    $getIntAction = (Get-Command Get-AntiJohnInt).ScriptBlock.GetNewClosure()
    $showResultAction = (Get-Command Show-AntiJohnResult).ScriptBlock.GetNewClosure()

    $showPageError = {
        param([string]$message)
        $ui.ResultStatus.Text = '操作失败'
        $ui.ResultStatus.Foreground = '#EF6B73'
        $ui.StatusLine.Text = $message
        Add-CkLogLine -TextBox $ui.LogBox -Line "[工具箱] $message"
        [System.Windows.MessageBox]::Show($message, 'CK免费工具箱 - 扫描移除后门') | Out-Null
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
        }
        $owner = [System.Windows.Window]::GetWindow($root)
        $accepted = if ($owner) { $dialog.ShowDialog($owner) } else { $dialog.ShowDialog() }
        if ($accepted -ne $true) { return }
        $selected = [IO.Path]::GetFullPath($dialog.FileName)
        if ([IO.Path]::GetFileName($selected) -ine 'python.exe') { throw '请选择 Python 安装目录中的 python.exe。' }
        $info = Test-CkPythonExecutable -Path $selected
        if (-not $info.Ok) { throw [string]$info.Reason }
        [void](Set-CkDependencyPath -Dependency Python -Path $selected)
        & $updateEnvironmentAction
    }.GetNewClosure()

    $chooseFolderAction = {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = '选择 FiveM resource 或 resources 目录'
        $dialog.SelectedPath = $ui.TargetBox.Text
        $dialog.ShowNewFolderButton = $false
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $ui.TargetBox.Text = $dialog.SelectedPath
                $state.TargetPath = $dialog.SelectedPath
            }
        } finally { $dialog.Dispose() }
    }.GetNewClosure()

    $chooseZipAction = {
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Title = '选择需要静态扫描的 ZIP'
        $dialog.Filter = 'ZIP 压缩包 (*.zip)|*.zip'
        $dialog.CheckFileExists = $true
        $dialog.Multiselect = $false
        $dialog.RestoreDirectory = $true
        $current = $ui.TargetBox.Text.Trim()
        if (Test-Path -LiteralPath $current -PathType Leaf) { $dialog.InitialDirectory = Split-Path -Parent $current }
        $owner = [System.Windows.Window]::GetWindow($root)
        $accepted = if ($owner) { $dialog.ShowDialog($owner) } else { $dialog.ShowDialog() }
        if ($accepted -eq $true) {
            $ui.TargetBox.Text = $dialog.FileName
            $state.TargetPath = $dialog.FileName
        }
    }.GetNewClosure()

    $openTargetAction = {
        $path = $ui.TargetBox.Text.Trim()
        if (Test-Path -LiteralPath $path -PathType Container) {
            Start-Process -FilePath explorer.exe -ArgumentList @($path)
        } elseif (Test-Path -LiteralPath $path -PathType Leaf) {
            Start-Process -FilePath explorer.exe -ArgumentList @((Split-Path -Parent $path))
        } else {
            throw "目标不存在: $path"
        }
    }.GetNewClosure()

    $chooseStateDirAction = {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = '选择后门扫描组件备份目录'
        $dialog.SelectedPath = $ui.StateDirBox.Text
        $dialog.ShowNewFolderButton = $true
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $ui.StateDirBox.Text = $dialog.SelectedPath }
        } finally { $dialog.Dispose() }
    }.GetNewClosure()

    $openBackupsAction = {
        $selected = $ui.StateDirBox.Text.Trim()
        if (-not $selected) {
            $target = $ui.TargetBox.Text.Trim()
            if (-not $target) { throw '请先选择目标。' }
            $targetPath = [IO.Path]::GetFullPath($target)
            $selected = Join-Path (Split-Path -Parent $targetPath) '.ck-anti-john-backups'
        }
        if (-not (Test-Path -LiteralPath $selected -PathType Container)) { throw "备份目录不存在: $selected" }
        Start-Process -FilePath explorer.exe -ArgumentList @($selected)
    }.GetNewClosure()

    function Start-AntiJohnOperation {
        param([ValidateSet('scan','preview','apply','restore')][string]$Operation)

        if ($state.Process -and -not $state.Process.Process.HasExited) { throw '已有后门扫描任务正在运行。' }
        if (-not (Test-Path -LiteralPath $Context.Paths.AntiJohnScript -PathType Leaf)) {
            throw "后门扫描组件入口不存在: $($Context.Paths.AntiJohnScript)"
        }

        $target = $ui.TargetBox.Text.Trim()
        $isDirectory = Test-Path -LiteralPath $target -PathType Container
        $isFile = Test-Path -LiteralPath $target -PathType Leaf
        if ([string]::IsNullOrWhiteSpace($target) -or (-not $isDirectory -and -not $isFile)) {
            throw '请选择具体的 FiveM resource、resources 目录或 ZIP。'
        }
        $fullTarget = [IO.Path]::GetFullPath($target).TrimEnd('\')
        if ($isFile -and [IO.Path]::GetExtension($fullTarget) -ine '.zip') { throw '文件目标只支持 ZIP。' }
        if ($isDirectory) {
            $driveRoot = [IO.Path]::GetPathRoot($fullTarget).TrimEnd('\')
            $workspaceRoot = [IO.Path]::GetFullPath($Context.Paths.WorkspaceRoot).TrimEnd('\')
            $componentRoot = [IO.Path]::GetFullPath($Context.Paths.AntiJohnDir).TrimEnd('\')
            if ($fullTarget.Equals($driveRoot, [StringComparison]::OrdinalIgnoreCase)) { throw '不能扫描整个磁盘。' }
            if ($fullTarget.Equals($workspaceRoot, [StringComparison]::OrdinalIgnoreCase)) { throw '不能扫描整个工具箱工作区。' }
            if ($fullTarget.Equals($componentRoot, [StringComparison]::OrdinalIgnoreCase)) { throw '不能扫描组件自身目录。' }
        }
        $target = $fullTarget
        $state.TargetPath = $target

        $maxMb = [int]::Parse($ui.MaxMbBox.Text.Trim(), [Globalization.CultureInfo]::InvariantCulture)
        if ($maxMb -lt 1 -or $maxMb -gt 1024) { throw '单文件上限必须在 1 到 1024 MB 之间。' }
        $python = & $getPythonAction
        $args = @('-u', $Context.Paths.AntiJohnScript)
        $label = ''
        if ($Operation -eq 'scan') {
            $args += @('scan', $target, '--max-bytes', [string]($maxMb * 1MB), '--json')
            $label = '正在扫描后门'
        } elseif ($Operation -in @('preview','apply')) {
            if ($Operation -eq 'apply') {
                $detail = if ($isDirectory) { '匹配文件会在目标外备份后精确修改。' } else { '原 ZIP 不变，将生成新的 .cleaned.zip。' }
                $answer = [System.Windows.MessageBox]::Show(
                    "即将移除可自动处理的后门：`n$target`n`n$detail`n写入后会自动静态复检。是否继续？",
                    '确认执行后门移除',
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Warning
                )
                if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
            }
            $args += @('repair', $target, '--max-bytes', [string]($maxMb * 1MB))
            $stateDir = $ui.StateDirBox.Text.Trim()
            if ($stateDir) { $args += @('--state-dir', $stateDir) }
            if ($Operation -eq 'apply') { $args += '--write' }
            $args += '--json'
            $label = if ($Operation -eq 'apply') { '正在移除后门' } else { '正在生成移除预览' }
        } else {
            $runId = $ui.RunIdBox.Text.Trim()
            if (-not $runId) { throw '请输入需要恢复的 Run ID。' }
            $answer = [System.Windows.MessageBox]::Show(
                "即将恢复 Run ID：$runId`n目标：$target`n`n是否继续？",
                '确认恢复备份',
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
            $args += @('restore', $target, '--run-id', $runId, '--write')
            $stateDir = $ui.StateDirBox.Text.Trim()
            if ($stateDir) { $args += @('--state-dir', $stateDir) }
            if ($ui.ForceRestoreBox.IsChecked) { $args += '--force' }
            $args += '--json'
            $label = '正在恢复备份'
        }

        $state.LastOperation = $Operation
        $state.CancelRequested = $false
        $ui.LogBox.Text = ''
        $ui.ProgressBar.Value = 0
        & $setRunningAction $true $label

        $output = New-Object Text.StringBuilder
        $callbackOutput = $output
        $callbackState = $state
        $callbackUi = $ui
        $callbackShowResult = $showResultAction
        $callbackSetRunning = $setRunningAction

        $onOutput = {
            param($line)
            [void]$callbackOutput.AppendLine($line)
            $callbackUi.ProgressBar.Value = [Math]::Min(86, $callbackUi.ProgressBar.Value + 5)
        }.GetNewClosure()
        $onProcessError = { param($message) $callbackUi.StatusLine.Text = $message }.GetNewClosure()
        $onExit = {
            param($exitCode)
            $wasCancelled = $callbackState.CancelRequested
            $callbackState.CancelRequested = $false
            $callbackState.Process = $null
            & $callbackSetRunning $false
            if ($wasCancelled) {
                $callbackUi.ProgressBar.Value = 0
                $callbackUi.ResultStatus.Text = '任务已停止'
                $callbackUi.ResultStatus.Foreground = '#F4B860'
                $callbackUi.StatusLine.Text = '当前任务已停止。'
                $callbackUi.LogBox.Text = '任务已由用户停止。'
                return
            }
            $raw = $callbackOutput.ToString().Trim()
            $payload = $null
            try { if ($raw) { $payload = $raw | ConvertFrom-Json } } catch { }
            if (-not $payload) {
                $lines = @($raw -split '\r?\n')
                for ($i = $lines.Count - 1; $i -ge 0 -and -not $payload; $i--) {
                    try { $payload = $lines[$i] | ConvertFrom-Json } catch { }
                }
            }
            if ($payload) {
                & $callbackShowResult $payload $exitCode
            } else {
                $callbackUi.ProgressBar.Value = 94
                $callbackUi.ResultStatus.Text = '结果解析失败'
                $callbackUi.ResultStatus.Foreground = '#EF6B73'
                $callbackUi.StatusLine.Text = "进程退出码: $exitCode"
                $callbackUi.LogBox.Text = if ($raw) { $raw } else { '后门扫描组件没有返回结果。' }
            }
        }.GetNewClosure()

        try {
            $state.Process = Start-CkLoggedProcess -FileName $python -Arguments $args -WorkingDirectory $Context.Paths.AntiJohnDir -Dispatcher $Context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onProcessError
        } catch {
            & $setRunningAction $false
            throw
        }
    }

    $startOperationAction = (Get-Command Start-AntiJohnOperation).ScriptBlock.GetNewClosure()
    $scanAction = { & $startOperationAction 'scan' }.GetNewClosure()
    $previewAction = { & $startOperationAction 'preview' }.GetNewClosure()
    $applyAction = { $ui.ResultStatus.Text = '等待确认'; & $startOperationAction 'apply' }.GetNewClosure()
    $restoreAction = { $ui.ResultStatus.Text = '等待确认'; & $startOperationAction 'restore' }.GetNewClosure()
    $cancelAction = {
        if (-not $state.Process -or $state.Process.Process.HasExited) { return }
        $state.CancelRequested = $true
        $ui.CancelButton.IsEnabled = $false
        $ui.ResultStatus.Text = '正在停止'
        $ui.ResultStatus.Foreground = '#F4B860'
        $ui.StatusLine.Text = '正在停止当前任务...'
        try { $state.Process.Process.Kill() } catch { $state.CancelRequested = $false; throw "停止任务失败: $($_.Exception.Message)" }
    }.GetNewClosure()

    Register-CkButtonAction -Button $ui.PythonDownloadButton -Action $openPythonDownloadAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.PythonBrowseButton -Action $selectPythonAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseFolderButton -Action $chooseFolderAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseZipButton -Action $chooseZipAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenTargetButton -Action $openTargetAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseStateDirButton -Action $chooseStateDirAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenBackupsButton -Action $openBackupsAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ScanButton -Action $scanAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.PreviewButton -Action $previewAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ApplyButton -Action $applyAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.CancelButton -Action $cancelAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.RestoreButton -Action $restoreAction -OnError $showPageError

    & $updateEnvironmentAction

    return [pscustomobject]@{
        Id = 'anti-john'
        Title = '扫描移除后门'
        Icon = '⊘'
        Root = $root
        Activate = $updateEnvironmentAction
    }
}
