function New-CkXiaohaCleanerPage {
    param([Parameter(Mandatory)]$Context)

    $state = [pscustomobject]@{
        Process = $null
        CancelRequested = $false
        ReportPath = ''
        QuarantinePath = ''
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
            <Border Width="4" Height="22" CornerRadius="3" Background="#F4B860" Margin="0,0,10,0"/>
            <TextBlock Text="一键清理小哈" FontSize="22" FontWeight="Bold"/>
          </StackPanel>
          <TextBlock Text="移除 Xiaoha / HGAdmin 资源、注入、启动项和已确认数据库对象" Foreground="#777B83" FontSize="13" Margin="14,6,0,0"/>
        </StackPanel>
        <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
          <Ellipse x:Name="EnvironmentDot" Width="10" Height="10" Fill="#31D69A" Margin="0,0,8,0"/>
          <TextBlock x:Name="EnvironmentText" AutomationProperties.AutomationId="XiaohaCleaner.EnvironmentText" Text="检测中" Foreground="#31D69A" FontWeight="SemiBold" Margin="0,0,10,0"/>
          <Button x:Name="PythonDownloadButton" AutomationProperties.AutomationId="XiaohaCleaner.PythonDownloadButton" Content="官网" Width="52" Height="28" Margin="0,0,6,0" Foreground="#58A6FF" Visibility="Collapsed" ToolTip="打开 Python 官方 Windows 下载页面"/>
          <Button x:Name="PythonBrowseButton" AutomationProperties.AutomationId="XiaohaCleaner.PythonBrowseButton" Content="选择" Width="52" Height="28" ToolTip="选择 Python 安装目录中的 python.exe"/>
        </StackPanel>
      </Grid>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="FiveM 服务器目录" Foreground="#B8C0CC" FontSize="13" Margin="0,0,0,6"/>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions>
          <TextBox x:Name="TargetBox" AutomationProperties.AutomationId="XiaohaCleaner.TargetBox" Height="38"/>
          <Button x:Name="ChooseTargetButton" AutomationProperties.AutomationId="XiaohaCleaner.ChooseTargetButton" Grid.Column="1" Content="选择目录" Height="38" Margin="8,0,0,0" Background="#173055" Foreground="#58A6FF"/>
          <Button x:Name="OpenTargetButton" Grid.Column="2" Content="打开位置" Height="38" Margin="8,0,0,0"/>
        </Grid>
        <TextBlock Text="请选择 server-data、resources 或其具体父目录；扫描只读取文件，不执行资源代码。" Foreground="#6E7580" FontSize="12" Margin="0,8,0,0"/>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="86"/></Grid.ColumnDefinitions>
        <StackPanel>
          <TextBlock Text="server.cfg（可选；留空自动查找并跟随 exec 配置链）" Foreground="#8B9099" FontSize="13" Margin="0,0,0,6"/>
          <TextBox x:Name="ServerCfgBox" AutomationProperties.AutomationId="XiaohaCleaner.ServerCfgBox" Height="38"/>
        </StackPanel>
        <Button x:Name="ChooseServerCfgButton" Grid.Column="1" Content="选择" Height="38" Margin="8,23,0,0"/>
      </Grid>
    </Border>

    <Border Background="#101214" BorderBrush="#5A3B21" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="数据库清理（危险操作，默认关闭）" Foreground="#F4B860" FontSize="15" FontWeight="Bold" Margin="0,0,0,10"/>
        <CheckBox x:Name="SqlCleanupBox" AutomationProperties.AutomationId="XiaohaCleaner.SqlCleanupBox" Content="同时删除小哈/HGAdmin 创建的表和新增列" Margin="0,0,0,8"/>
        <CheckBox x:Name="DatabaseBackupBox" AutomationProperties.AutomationId="XiaohaCleaner.DatabaseBackupBox" Content="我已停止服务器并完成数据库备份" Margin="0,0,0,10"/>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="86"/></Grid.ColumnDefinitions>
          <StackPanel>
            <TextBlock Text="mysql.exe / mariadb.exe（可选；留空从 PATH 查找）" Foreground="#8B9099" FontSize="13" Margin="0,0,0,6"/>
            <TextBox x:Name="MysqlExeBox" AutomationProperties.AutomationId="XiaohaCleaner.MysqlExeBox" Height="38"/>
          </StackPanel>
          <Button x:Name="ChooseMysqlButton" Grid.Column="1" Content="选择" Height="38" Margin="8,23,0,0"/>
        </Grid>
        <TextBlock Text="数据库模式会删除 bans、warns、14 张样本确认表、3 个新增列和名称含 xiaoha/hgadmin 的表；只能从数据库备份恢复。" Foreground="#D89078" FontSize="12" TextWrapping="Wrap" Margin="0,8,0,0"/>
      </StackPanel>
    </Border>

    <Grid Margin="0,0,0,14">
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="0.72*"/></Grid.ColumnDefinitions>
      <Button x:Name="ScanButton" AutomationProperties.AutomationId="XiaohaCleaner.ScanButton" Grid.Column="0" Content="只读扫描" Height="46" Margin="0,0,6,0"/>
      <Button x:Name="CleanButton" AutomationProperties.AutomationId="XiaohaCleaner.CleanButton" Grid.Column="1" Content="执行清理" Height="46" Margin="6,0" Background="#5A2026" Foreground="#FF9CA3" FontWeight="Bold"/>
      <Button x:Name="CancelButton" AutomationProperties.AutomationId="XiaohaCleaner.CancelButton" Grid.Column="2" Content="停止任务" Height="46" Margin="6,0,0,0" Foreground="#F28B94" IsEnabled="False"/>
    </Grid>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/><ColumnDefinition Width="112"/><ColumnDefinition Width="112"/></Grid.ColumnDefinitions>
        <StackPanel>
          <TextBlock Text="文件恢复报告 run-report.json" Foreground="#8B9099" FontSize="13" Margin="0,0,0,6"/>
          <TextBox x:Name="RestoreReportBox" AutomationProperties.AutomationId="XiaohaCleaner.RestoreReportBox" Height="38"/>
        </StackPanel>
        <Button x:Name="ChooseReportButton" Grid.Column="1" Content="选择" Height="38" Margin="8,23,0,0"/>
        <Button x:Name="RestoreButton" AutomationProperties.AutomationId="XiaohaCleaner.RestoreButton" Grid.Column="2" Content="恢复文件" Height="38" Margin="8,23,0,0" Foreground="#EF9A9A"/>
        <Button x:Name="OpenReportButton" Grid.Column="3" Content="打开报告" Height="38" Margin="8,23,0,0"/>
      </Grid>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12">
          <TextBlock Text="清理结果" FontSize="20" FontWeight="Bold"/>
          <TextBlock x:Name="ResultStatus" AutomationProperties.AutomationId="XiaohaCleaner.ResultStatus" Text="等待任务" HorizontalAlignment="Right" Foreground="#777B83" FontSize="14"/>
        </Grid>
        <UniformGrid Columns="6" Margin="0,0,0,14">
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="0,0,4,0"><StackPanel><TextBlock Text="资源" Foreground="#777B83"/><TextBlock x:Name="ResourceCount" Text="0" FontSize="19" FontWeight="Bold"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="文件" Foreground="#777B83"/><TextBlock x:Name="FileCount" Text="0" FontSize="19" FontWeight="Bold"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="体积" Foreground="#777B83"/><TextBlock x:Name="SizeText" Text="0 B" FontSize="19" FontWeight="Bold"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="守卫" Foreground="#777B83"/><TextBlock x:Name="GuardCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#F4B860"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="SQL 表" Foreground="#777B83"/><TextBlock x:Name="SqlCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#EF6B73"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0,0,0"><StackPanel><TextBlock Text="外部引用" Foreground="#777B83"/><TextBlock x:Name="ReferenceCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#58A6FF"/></StackPanel></Border>
        </UniformGrid>
        <ProgressBar x:Name="ProgressBar" Height="8" Minimum="0" Maximum="100" Value="0"/>
        <TextBlock x:Name="StatusLine" AutomationProperties.AutomationId="XiaohaCleaner.StatusLine" Text="先执行只读扫描，确认范围后再清理。" Foreground="#8B9099" FontSize="14" Margin="0,10,0,0"/>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16">
      <StackPanel>
        <TextBlock Text="报告明细" FontSize="20" FontWeight="Bold" Margin="0,0,0,10"/>
        <TextBox x:Name="LogBox" AutomationProperties.AutomationId="XiaohaCleaner.LogBox" MinHeight="230" MaxHeight="460" AcceptsReturn="True" TextWrapping="NoWrap" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" IsReadOnly="True" Text="等待任务输出..."/>
      </StackPanel>
    </Border>
  </StackPanel>
</ScrollViewer>
"@

    $root = Import-CkXaml $xaml
    $ui = Get-CkNamedControls -Root $root -Names @(
        'EnvironmentDot','EnvironmentText','PythonDownloadButton','PythonBrowseButton','TargetBox','ChooseTargetButton',
        'OpenTargetButton','ServerCfgBox','ChooseServerCfgButton','SqlCleanupBox','DatabaseBackupBox','MysqlExeBox',
        'ChooseMysqlButton','ScanButton','CleanButton','CancelButton','RestoreReportBox','ChooseReportButton','RestoreButton',
        'OpenReportButton','ResultStatus','ResourceCount','FileCount','SizeText','GuardCount','SqlCount','ReferenceCount',
        'ProgressBar','StatusLine','LogBox'
    )

    function Get-XiaohaPythonInfo {
        $environment = Get-CkToolboxEnvironment -Context $Context
        $blenderPath = if ($environment.Blender.Ok) { $environment.Blender.Path } else { '' }
        $settings = Get-CkDependencySettings
        return Get-CkPythonInfo -RuntimeRoot $Context.Paths.RuntimeRoot -BlenderExe $blenderPath -ConfiguredPath ([string]$settings.PythonPath)
    }

    function Get-XiaohaPython {
        $info = & $getPythonInfoAction
        if (-not $info.Ok) { throw [string]$info.Reason }
        return [string]$info.Path
    }

    function Update-XiaohaEnvironment {
        $scriptOk = Test-Path -LiteralPath $Context.Paths.XiaohaCleanerScript -PathType Leaf
        $pythonInfo = & $getPythonInfoAction
        $pythonOk = [bool]$pythonInfo.Ok
        $ok = $scriptOk -and $pythonOk
        Set-CkStatusDot $ui.EnvironmentDot $ok
        $ui.EnvironmentText.Foreground = if ($ok) { '#31D69A' } else { '#EF6B73' }
        $ui.EnvironmentText.Text = if ($ok) { "运行环境就绪 · $($pythonInfo.Label)" } elseif (-not $scriptOk) { '缺少小哈清理组件' } else { '缺少 Python 3.7+' }
        $ui.EnvironmentText.ToolTip = if ($pythonOk) { [string]$pythonInfo.Path } else { [string]$pythonInfo.Reason }
        $ui.PythonDownloadButton.Visibility = if ($pythonOk) { 'Collapsed' } else { 'Visible' }
        $ui.PythonBrowseButton.Content = if ($pythonOk) { '更改' } else { '选择' }
    }

    function Set-XiaohaRunning {
        param([bool]$Running, [string]$Label = '')
        foreach ($button in @(
            $ui.ScanButton,$ui.CleanButton,$ui.RestoreButton,$ui.PythonDownloadButton,$ui.PythonBrowseButton,
            $ui.ChooseTargetButton,$ui.ChooseServerCfgButton,$ui.ChooseMysqlButton,$ui.ChooseReportButton
        )) { $button.IsEnabled = -not $Running }
        $ui.CancelButton.IsEnabled = $Running
        $ui.ProgressBar.IsIndeterminate = $Running
        if ($Running) {
            $ui.ResultStatus.Text = $Label
            $ui.ResultStatus.Foreground = '#58A6FF'
            $ui.StatusLine.Text = '正在运行小哈清理组件，可随时停止任务。'
            $ui.ProgressBar.Value = 18
        } else {
            $ui.ProgressBar.IsIndeterminate = $false
        }
    }

    function Get-XiaohaProperty {
        param($Object, [string]$Name, $Default = $null)
        if ($Object -and $Object.PSObject.Properties[$Name]) { return $Object.$Name }
        return $Default
    }

    function Get-XiaohaInt {
        param($Object, [string]$Name)
        $value = & $getPropertyAction $Object $Name 0
        if ($null -eq $value) { return 0 }
        return [int64]$value
    }

    function Format-XiaohaBytes {
        param([int64]$Bytes)
        if ($Bytes -ge 1GB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
        if ($Bytes -ge 1MB) { return ('{0:N2} MB' -f ($Bytes / 1MB)) }
        if ($Bytes -ge 1KB) { return ('{0:N2} KB' -f ($Bytes / 1KB)) }
        return "$Bytes B"
    }

    function Show-XiaohaResult {
        param($Payload, [int]$ExitCode, [string]$RawOutput = '')

        $summary = & $getPropertyAction $Payload 'summary' $null
        $resources = & $getPropertyAction $Payload 'resources' $null
        $sql = & $getPropertyAction $Payload 'sql' $null
        $owned = @(& $getPropertyAction $resources 'owned' @())
        $tables = @(& $getPropertyAction $sql 'safe_tables' @())
        $references = @(& $getPropertyAction $Payload 'external_references' @())
        $ui.ResourceCount.Text = [string](& $getIntAction $summary 'owned_resources')
        $ui.FileCount.Text = [string](& $getIntAction $summary 'resource_files')
        $ui.SizeText.Text = & $formatBytesAction (& $getIntAction $summary 'resource_bytes')
        $ui.GuardCount.Text = [string](& $getIntAction $summary 'injection_files')
        $ui.SqlCount.Text = [string](& $getIntAction $summary 'safe_sql_tables')
        $ui.ReferenceCount.Text = [string](& $getIntAction $summary 'external_references')

        $status = [string](& $getPropertyAction $Payload 'status' '')
        $success = ($ExitCode -eq 0) -and ($status -notmatch 'failed|error')
        $ui.ProgressBar.Value = if ($success) { 100 } else { 94 }
        $ui.ResultStatus.Text = if ($success) { if ($status -eq 'scan') { '扫描完成' } elseif ($status -eq 'cleaned') { '清理完成' } else { '任务完成' } } else { '任务有错误' }
        $ui.ResultStatus.Foreground = if ($success) { '#31D69A' } else { '#EF6B73' }
        $ui.StatusLine.Text = if ($success) { '报告已生成；执行数据库清理前请确认备份。' } else { "进程退出码: $ExitCode" }

        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add("状态: $status")
        $lines.Add("目标: $(& $getPropertyAction $Payload 'target' '')")
        $lines.Add("确认资源: $($owned.Count)")
        foreach ($item in $owned | Select-Object -First 80) {
            $reason = @(& $getPropertyAction $item 'reasons' @()) -join ', '
            $lines.Add("  - $(& $getPropertyAction $item 'relative_path' '') [$reason]")
        }
        $lines.Add('')
        $lines.Add("数据库表: $($tables.Count)")
        foreach ($table in $tables) { $lines.Add("  - $table") }
        if ($references.Count) {
            $lines.Add('')
            $lines.Add("保留资源中的外部引用: $($references.Count)")
            foreach ($item in $references | Select-Object -First 60) {
                $lines.Add("  - $(& $getPropertyAction $item 'relative_path' ''):$(& $getPropertyAction $item 'line' 0)")
            }
        }
        $errorText = [string](& $getPropertyAction $Payload 'error' '')
        if ($errorText) { $lines.Add(''); $lines.Add("错误: $errorText") }
        if ($RawOutput) { $lines.Add(''); $lines.Add('组件输出:'); $lines.Add($RawOutput.Trim()) }
        $ui.LogBox.Text = $lines -join [Environment]::NewLine
    }

    $getPythonInfoAction = (Get-Command Get-XiaohaPythonInfo).ScriptBlock.GetNewClosure()
    $getPythonAction = (Get-Command Get-XiaohaPython).ScriptBlock.GetNewClosure()
    $updateEnvironmentAction = (Get-Command Update-XiaohaEnvironment).ScriptBlock.GetNewClosure()
    $setRunningAction = (Get-Command Set-XiaohaRunning).ScriptBlock.GetNewClosure()
    $getPropertyAction = (Get-Command Get-XiaohaProperty).ScriptBlock.GetNewClosure()
    $getIntAction = (Get-Command Get-XiaohaInt).ScriptBlock.GetNewClosure()
    $formatBytesAction = (Get-Command Format-XiaohaBytes).ScriptBlock.GetNewClosure()
    $showResultAction = (Get-Command Show-XiaohaResult).ScriptBlock.GetNewClosure()

    $showPageError = {
        param($message)
        & $setRunningAction $false
        $ui.ProgressBar.Value = 0
        $ui.ResultStatus.Text = '操作失败'
        $ui.ResultStatus.Foreground = '#EF6B73'
        $ui.StatusLine.Text = $message
        $ui.LogBox.Text = $message
        [System.Windows.MessageBox]::Show($message, 'CK免费工具箱 - 一键清理小哈') | Out-Null
    }.GetNewClosure()

    $openPythonDownloadAction = { Start-Process -FilePath 'https://www.python.org/downloads/windows/' }.GetNewClosure()

    $selectPythonAction = {
        $settings = Get-CkDependencySettings
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Title = '选择 Python 主程序 python.exe'
        $dialog.Filter = 'Python 主程序 (python.exe)|python.exe|可执行文件 (*.exe)|*.exe'
        $dialog.CheckFileExists = $true
        $dialog.Multiselect = $false
        if ($settings.PythonPath -and (Test-Path -LiteralPath ([string]$settings.PythonPath) -PathType Leaf)) {
            $dialog.InitialDirectory = Split-Path -Parent ([string]$settings.PythonPath)
            $dialog.FileName = [string]$settings.PythonPath
        }
        $owner = [System.Windows.Window]::GetWindow($root)
        $accepted = if ($owner) { $dialog.ShowDialog($owner) } else { $dialog.ShowDialog() }
        if ($accepted -ne $true) { return }
        $selected = [IO.Path]::GetFullPath($dialog.FileName)
        $info = Test-CkPythonExecutable -Path $selected
        if (-not $info.Ok) { throw [string]$info.Reason }
        [void](Set-CkDependencyPath -Dependency Python -Path $selected)
        & $updateEnvironmentAction
    }.GetNewClosure()

    $chooseTargetAction = {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = '选择 FiveM server-data、resources 或服务器目录'
        $dialog.SelectedPath = $ui.TargetBox.Text
        $dialog.ShowNewFolderButton = $false
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $ui.TargetBox.Text = $dialog.SelectedPath
                $candidate = Join-Path $dialog.SelectedPath 'server.cfg'
                if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                    $ui.ServerCfgBox.Text = $candidate
                } elseif ([IO.Path]::GetFileName($dialog.SelectedPath) -ieq 'resources') {
                    $candidate = Join-Path (Split-Path -Parent $dialog.SelectedPath) 'server.cfg'
                    if (Test-Path -LiteralPath $candidate -PathType Leaf) { $ui.ServerCfgBox.Text = $candidate }
                }
            }
        } finally { $dialog.Dispose() }
    }.GetNewClosure()

    $openTargetAction = {
        $path = $ui.TargetBox.Text.Trim()
        if (-not (Test-Path -LiteralPath $path -PathType Container)) { throw "目标目录不存在: $path" }
        Start-Process -FilePath explorer.exe -ArgumentList @($path)
    }.GetNewClosure()

    $chooseServerCfgAction = {
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Title = '选择 FiveM server.cfg'
        $dialog.Filter = 'FiveM 配置 (*.cfg)|*.cfg|所有文件 (*.*)|*.*'
        $dialog.CheckFileExists = $true
        $dialog.Multiselect = $false
        $owner = [System.Windows.Window]::GetWindow($root)
        $accepted = if ($owner) { $dialog.ShowDialog($owner) } else { $dialog.ShowDialog() }
        if ($accepted -eq $true) { $ui.ServerCfgBox.Text = $dialog.FileName }
    }.GetNewClosure()

    $chooseMysqlAction = {
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Title = '选择 mysql.exe 或 mariadb.exe'
        $dialog.Filter = 'MySQL/MariaDB 客户端 (*.exe)|mysql.exe;mariadb.exe|可执行文件 (*.exe)|*.exe'
        $dialog.CheckFileExists = $true
        $dialog.Multiselect = $false
        $owner = [System.Windows.Window]::GetWindow($root)
        $accepted = if ($owner) { $dialog.ShowDialog($owner) } else { $dialog.ShowDialog() }
        if ($accepted -eq $true) { $ui.MysqlExeBox.Text = $dialog.FileName }
    }.GetNewClosure()

    $chooseReportAction = {
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Title = '选择清理生成的 run-report.json'
        $dialog.Filter = '运行报告 (run-report.json)|run-report.json|JSON 文件 (*.json)|*.json'
        $dialog.CheckFileExists = $true
        $dialog.Multiselect = $false
        $owner = [System.Windows.Window]::GetWindow($root)
        $accepted = if ($owner) { $dialog.ShowDialog($owner) } else { $dialog.ShowDialog() }
        if ($accepted -eq $true) { $ui.RestoreReportBox.Text = $dialog.FileName }
    }.GetNewClosure()

    $openReportAction = {
        $path = $ui.RestoreReportBox.Text.Trim()
        if (-not $path) { $path = $state.ReportPath }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw '报告文件不存在。' }
        Start-Process -FilePath explorer.exe -ArgumentList @((Split-Path -Parent $path))
    }.GetNewClosure()

    function Start-XiaohaOperation {
        param([ValidateSet('scan','clean','restore')][string]$Operation)

        if ($state.Process -and -not $state.Process.Process.HasExited) { throw '已有小哈清理任务正在运行。' }
        if (-not (Test-Path -LiteralPath $Context.Paths.XiaohaCleanerScript -PathType Leaf)) {
            throw "小哈清理组件入口不存在: $($Context.Paths.XiaohaCleanerScript)"
        }
        $python = & $getPythonAction
        $args = @('-u', $Context.Paths.XiaohaCleanerScript)
        $expectedReport = ''
        $label = ''

        if ($Operation -eq 'restore') {
            $report = $ui.RestoreReportBox.Text.Trim()
            if (-not (Test-Path -LiteralPath $report -PathType Leaf)) { throw '请选择有效的 run-report.json。' }
            if ([IO.Path]::GetFileName($report) -ine 'run-report.json') { throw '恢复只接受 run-report.json。' }
            $answer = [System.Windows.MessageBox]::Show(
                "即将按报告恢复文件系统修改：`n$report`n`n数据库 DROP 操作不会恢复。是否继续？",
                '确认恢复文件',
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
            $args += @('restore', [IO.Path]::GetFullPath($report), '--yes')
            $expectedReport = Join-Path (Split-Path -Parent $report) 'restore-report.json'
            $label = '正在恢复文件'
        } else {
            $target = $ui.TargetBox.Text.Trim()
            if (-not (Test-Path -LiteralPath $target -PathType Container)) { throw '请选择有效的 FiveM 服务器目录。' }
            $target = [IO.Path]::GetFullPath($target).TrimEnd('\')
            $driveRoot = [IO.Path]::GetPathRoot($target).TrimEnd('\')
            $workspaceRoot = [IO.Path]::GetFullPath($Context.Paths.WorkspaceRoot).TrimEnd('\')
            $componentRoot = [IO.Path]::GetFullPath($Context.Paths.XiaohaCleanerDir).TrimEnd('\')
            if ($target.Equals($driveRoot, [StringComparison]::OrdinalIgnoreCase)) { throw '不能扫描整个磁盘。' }
            if ($target.Equals($workspaceRoot, [StringComparison]::OrdinalIgnoreCase)) { throw '不能扫描整个工具箱工作区。' }
            if ($target.Equals($componentRoot, [StringComparison]::OrdinalIgnoreCase)) { throw '不能扫描组件自身目录。' }

            if ($Operation -eq 'scan') {
                $reportBase = Join-Path (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CKFreeToolbox') 'xiaoha-cleaner-reports'
                $reportDir = Join-Path $reportBase ((Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 6))
                $args += @('scan', $target, '--output', $reportDir)
                $expectedReport = Join-Path $reportDir 'scan-report.json'
                $label = '正在只读扫描'
            } else {
                $sqlCleanup = [bool]$ui.SqlCleanupBox.IsChecked
                if ($sqlCleanup -and -not [bool]$ui.DatabaseBackupBox.IsChecked) {
                    throw '启用数据库清理前，必须确认已停止服务器并完成数据库备份。'
                }
                $warning = "即将隔离确认归属的小哈/HGAdmin 资源并修改启动引用：`n$target"
                if ($sqlCleanup) {
                    $warning += "`n`n同时会删除数据库表和新增列，包括 bans、warns。数据库只能从备份恢复。"
                } else {
                    $warning += "`n`n本次不会连接数据库，只会生成 cleanup_database.sql。"
                }
                $answer = [System.Windows.MessageBox]::Show(
                    "$warning`n`n是否继续？",
                    '确认执行小哈清理',
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Warning
                )
                if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
                $args += @('clean', $target, '--yes')
                if ($sqlCleanup) {
                    $args += @('--apply-sql', '--yes-drop-tables')
                    $serverCfg = $ui.ServerCfgBox.Text.Trim()
                    if ($serverCfg) {
                        if (-not (Test-Path -LiteralPath $serverCfg -PathType Leaf)) { throw "server.cfg 不存在: $serverCfg" }
                        $args += @('--server-cfg', [IO.Path]::GetFullPath($serverCfg))
                    }
                    $mysqlExe = $ui.MysqlExeBox.Text.Trim()
                    if ($mysqlExe) {
                        if (-not (Test-Path -LiteralPath $mysqlExe -PathType Leaf)) { throw "MySQL 客户端不存在: $mysqlExe" }
                        $args += @('--mysql-command', [IO.Path]::GetFullPath($mysqlExe))
                    }
                }
                $label = if ($sqlCleanup) { '正在清理资源与数据库' } else { '正在清理资源与代码' }
            }
        }

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
        $callbackExpectedReport = $expectedReport
        $callbackOperation = $Operation

        $onOutput = {
            param($line)
            [void]$callbackOutput.AppendLine($line)
            $callbackUi.ProgressBar.Value = [Math]::Min(88, $callbackUi.ProgressBar.Value + 4)
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
            $reportPath = $callbackExpectedReport
            if ($callbackOperation -eq 'clean') {
                $match = [regex]::Match($raw, '(?im)^Quarantine/report:\s*(.+?)\s*$')
                if ($match.Success) {
                    $runDir = $match.Groups[1].Value.Trim()
                    $callbackState.QuarantinePath = $runDir
                    $reportPath = Join-Path $runDir 'run-report.json'
                }
            }
            $payload = $null
            if ($reportPath -and (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
                try {
                    $payload = Get-Content -LiteralPath $reportPath -Raw -Encoding UTF8 | ConvertFrom-Json
                    $callbackState.ReportPath = $reportPath
                    if ([IO.Path]::GetFileName($reportPath) -ieq 'run-report.json') {
                        $callbackUi.RestoreReportBox.Text = $reportPath
                    }
                } catch { }
            }
            if ($payload) {
                & $callbackShowResult $payload $exitCode $raw
            } else {
                $callbackUi.ProgressBar.Value = 94
                $callbackUi.ResultStatus.Text = '任务失败'
                $callbackUi.ResultStatus.Foreground = '#EF6B73'
                $callbackUi.StatusLine.Text = "进程退出码: $exitCode"
                $callbackUi.LogBox.Text = if ($raw) { $raw } else { '小哈清理组件没有返回报告。' }
            }
        }.GetNewClosure()

        try {
            $state.Process = Start-CkLoggedProcess -FileName $python -Arguments $args -WorkingDirectory $Context.Paths.XiaohaCleanerDir -Dispatcher $Context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onProcessError
        } catch {
            & $setRunningAction $false
            throw
        }
    }

    $startOperationAction = (Get-Command Start-XiaohaOperation).ScriptBlock.GetNewClosure()
    $scanAction = { & $startOperationAction 'scan' }.GetNewClosure()
    $cleanAction = { $ui.ResultStatus.Text = '等待确认'; & $startOperationAction 'clean' }.GetNewClosure()
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
    Register-CkButtonAction -Button $ui.ChooseTargetButton -Action $chooseTargetAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenTargetButton -Action $openTargetAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseServerCfgButton -Action $chooseServerCfgAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseMysqlButton -Action $chooseMysqlAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseReportButton -Action $chooseReportAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenReportButton -Action $openReportAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ScanButton -Action $scanAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.CleanButton -Action $cleanAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.RestoreButton -Action $restoreAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.CancelButton -Action $cancelAction -OnError $showPageError

    if ($Context.Paths.DefaultXiaohaCleanerInput) { $ui.TargetBox.Text = $Context.Paths.DefaultXiaohaCleanerInput }
    & $updateEnvironmentAction

    return [pscustomobject]@{
        Id = 'xiaoha-cleaner'
        Title = '一键清理小哈'
        Icon = '⌁'
        Root = $root
        Activate = $updateEnvironmentAction
    }
}
