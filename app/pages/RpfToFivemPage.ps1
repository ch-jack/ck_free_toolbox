function New-CkRpfToFivemPage {
    param([Parameter(Mandatory)]$Context)

    $rows = New-Object System.Collections.ObjectModel.ObservableCollection[object]
    $state = [pscustomobject]@{
        Process = $null
        CancelRequested = $false
        ReportPath = ''
    }

    $xaml = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
              xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
              VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"
              Padding="22,16,28,32">
  <ScrollViewer.Resources>
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#A4AAB4"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="VerticalAlignment" Value="Center"/>
    </Style>
  </ScrollViewer.Resources>
  <StackPanel>
    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12">
          <StackPanel Orientation="Horizontal">
            <Border Width="4" Height="22" CornerRadius="3" Background="#58A6FF" Margin="0,0,10,0"/>
            <StackPanel><TextBlock Text="RPF 转 FiveM" FontSize="21" FontWeight="Bold"/><TextBlock Text="批量提取 RPF 并生成可直接使用的 FiveM resource" Foreground="#777B83" FontSize="12" Margin="0,4,0,0"/></StackPanel>
          </StackPanel>
          <TextBlock x:Name="EnvironmentStatus" AutomationProperties.AutomationId="RpfToFivem.EnvironmentStatus" Text="检测中" HorizontalAlignment="Right" VerticalAlignment="Center" Foreground="#F4B860" FontSize="14" FontWeight="SemiBold"/>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Border Grid.Column="0" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="0,0,5,0">
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/><ColumnDefinition Width="94"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="PythonDot" Width="9" Height="9" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1"><TextBlock Text="Python" FontSize="14" FontWeight="SemiBold"/><TextBlock x:Name="PythonText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel>
              <StackPanel Grid.Column="2" Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="PythonDownloadButton" AutomationProperties.AutomationId="RpfToFivem.PythonDownloadButton" Content="官网" Width="42" Height="27" Margin="0,0,5,0" Foreground="#58A6FF" Visibility="Collapsed" ToolTip="打开 Python 官方 Windows 下载页面"/>
                <Button x:Name="PythonBrowseButton" AutomationProperties.AutomationId="RpfToFivem.PythonBrowseButton" Content="选择" Width="42" Height="27" ToolTip="选择 Python 安装目录中的 python.exe"/>
              </StackPanel>
            </Grid>
          </Border>
          <Border Grid.Column="1" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="5,0">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/><ColumnDefinition Width="48"/></Grid.ColumnDefinitions><Ellipse x:Name="DotNetDot" Width="9" Height="9" Fill="#31D69A" VerticalAlignment="Center"/><StackPanel Grid.Column="1"><TextBlock Text=".NET 4.8" FontSize="14" FontWeight="SemiBold"/><TextBlock x:Name="DotNetText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel><Button x:Name="DotNetButton" AutomationProperties.AutomationId="RpfToFivem.DotNetButton" Grid.Column="2" Content="官网" Height="27" Foreground="#58A6FF"/></Grid>
          </Border>
          <Border Grid.Column="2" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="5,0,0,0">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Ellipse x:Name="ComponentDot" Width="9" Height="9" Fill="#31D69A" VerticalAlignment="Center"/><StackPanel Grid.Column="1"><TextBlock Text="RPF 组件" FontSize="14" FontWeight="SemiBold"/><TextBlock x:Name="ComponentText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel></Grid>
          </Border>
        </Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="输入与输出" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid Margin="0,0,0,10">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="88"/><ColumnDefinition Width="88"/></Grid.ColumnDefinitions>
          <StackPanel><TextBlock Text="输入目录、RPF 或压缩包" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="InputBox" AutomationProperties.AutomationId="RpfToFivem.InputBox" Height="36"/></StackPanel>
          <Button x:Name="ChooseFileButton" AutomationProperties.AutomationId="RpfToFivem.ChooseFileButton" Grid.Column="1" Content="选择文件" Height="36" Margin="7,22,0,0" Background="#173055" Foreground="#58A6FF"/>
          <Button x:Name="ChooseFolderButton" AutomationProperties.AutomationId="RpfToFivem.ChooseFolderButton" Grid.Column="2" Content="选择目录" Height="36" Margin="7,22,0,0"/>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="88"/><ColumnDefinition Width="88"/></Grid.ColumnDefinitions>
          <StackPanel><TextBlock Text="FiveM 资源输出目录" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="OutputBox" AutomationProperties.AutomationId="RpfToFivem.OutputBox" Height="36"/></StackPanel>
          <Button x:Name="ChooseOutputButton" AutomationProperties.AutomationId="RpfToFivem.ChooseOutputButton" Grid.Column="1" Content="选择目录" Height="36" Margin="7,22,0,0" Background="#173055" Foreground="#58A6FF"/>
          <Button x:Name="OpenOutputButton" AutomationProperties.AutomationId="RpfToFivem.OpenOutputButton" Grid.Column="2" Content="打开输出" Height="36" Margin="7,22,0,0"/>
        </Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,10"><TextBlock Text="转换参数" FontSize="18" FontWeight="Bold"/><TextBlock Text="默认值适合大多数资源" HorizontalAlignment="Right" Foreground="#686E78" FontSize="12" VerticalAlignment="Center"/></Grid>
        <Grid Margin="0,0,0,10">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <StackPanel Grid.Column="0" Margin="0,0,7,0"><TextBlock Text="单次超时（秒）" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="TimeoutBox" Height="35" Text="600"/></StackPanel>
          <StackPanel Grid.Column="1" Margin="7,0"><TextBlock Text="嵌套压缩层数" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="DepthBox" Height="35" Text="3"/></StackPanel>
          <StackPanel Grid.Column="2" Margin="7,0,0,0"><TextBlock Text="压缩包数量上限" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="ArchivesBox" Height="35" Text="500"/></StackPanel>
        </Grid>
        <Grid Margin="0,0,0,12">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <StackPanel Grid.Column="0" Margin="0,0,7,0"><TextBlock Text="单包文件数上限" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="ArchiveFilesBox" Height="35" Text="200000"/></StackPanel>
          <StackPanel Grid.Column="1" Margin="7,0"><TextBlock Text="单包解压上限（GB）" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="UnpackedGbBox" Height="35" Text="50"/></StackPanel>
          <StackPanel Grid.Column="2" Margin="7,23,0,0" Orientation="Horizontal"><CheckBox x:Name="OverwriteBox" AutomationProperties.AutomationId="RpfToFivem.OverwriteBox" Content="覆盖同名资源" Margin="0,0,18,0"/><CheckBox x:Name="KeepWorkBox" AutomationProperties.AutomationId="RpfToFivem.KeepWorkBox" Content="保留临时目录"/></StackPanel>
        </Grid>
        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions><Button x:Name="StartButton" AutomationProperties.AutomationId="RpfToFivem.StartButton" Content="开始转换" Height="44" Margin="0,0,7,0" Background="#124834" Foreground="#54E0A9" FontSize="15" FontWeight="Bold"/><Button x:Name="StopButton" AutomationProperties.AutomationId="RpfToFivem.StopButton" Grid.Column="1" Content="停止任务" Height="44" Margin="7,0,0,0" Foreground="#F28B94" IsEnabled="False"/></Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12"><TextBlock Text="转换结果" FontSize="18" FontWeight="Bold"/><StackPanel Orientation="Horizontal" HorizontalAlignment="Right"><TextBlock x:Name="ResultStatus" AutomationProperties.AutomationId="RpfToFivem.ResultStatus" Text="等待任务" Foreground="#777B83" FontSize="13" VerticalAlignment="Center" Margin="0,0,10,0"/><Button x:Name="OpenReportButton" AutomationProperties.AutomationId="RpfToFivem.OpenReportButton" Content="打开报告" Height="28" IsEnabled="False"/></StackPanel></Grid>
        <UniformGrid Columns="5" Margin="0,0,0,12">
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="0,0,4,0"><StackPanel><TextBlock Text="发现 RPF" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="RpfCount" Text="0" FontSize="19" FontWeight="Bold"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="成功" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="SuccessCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#31D69A"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="失败" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="FailedCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#EF7C86"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="输出文件" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="OutputFileCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#58A6FF"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0,0,0"><StackPanel><TextBlock Text="警告" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="WarningCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#F4B860"/></StackPanel></Border>
        </UniformGrid>
        <ProgressBar x:Name="ProgressBar" AutomationProperties.AutomationId="RpfToFivem.ProgressBar" Height="8" Minimum="0" Maximum="100" Value="0"/>
        <TextBlock x:Name="StatusLine" AutomationProperties.AutomationId="RpfToFivem.StatusLine" Text="选择输入和输出后开始转换。" Foreground="#8B9099" FontSize="13" Margin="0,9,0,0"/>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,10"><TextBlock Text="资源明细" FontSize="18" FontWeight="Bold"/><TextBlock x:Name="ResourceCounter" Text="0 项" HorizontalAlignment="Right" Foreground="#777B83" FontSize="12"/></Grid>
        <ListView x:Name="ResourceList" AutomationProperties.AutomationId="RpfToFivem.ResourceList" MinHeight="120" MaxHeight="300" Background="#0D0F11" BorderBrush="#242833" BorderThickness="1" VirtualizingStackPanel.IsVirtualizing="True" VirtualizingStackPanel.VirtualizationMode="Recycling" ScrollViewer.CanContentScroll="True">
          <ListView.ItemTemplate><DataTemplate><Border BorderBrush="#20242C" BorderThickness="0,0,0,1" Padding="9"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="120"/><ColumnDefinition Width="*"/><ColumnDefinition Width="75"/><ColumnDefinition Width="65"/></Grid.ColumnDefinitions><TextBlock Text="{Binding Status}" Foreground="{Binding StatusColor}" FontWeight="SemiBold"/><StackPanel Grid.Column="1"><TextBlock Text="{Binding Name}" FontSize="13" FontWeight="SemiBold"/><TextBlock Text="{Binding Detail}" Foreground="#6F7580" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel><TextBlock Grid.Column="2" Text="{Binding FilesText}" Foreground="#58A6FF" VerticalAlignment="Center"/><TextBlock Grid.Column="3" Text="{Binding WarningsText}" Foreground="#F4B860" VerticalAlignment="Center"/></Grid></Border></DataTemplate></ListView.ItemTemplate>
        </ListView>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16">
      <StackPanel><TextBlock Text="任务日志" FontSize="18" FontWeight="Bold" Margin="0,0,0,9"/><TextBox x:Name="LogBox" AutomationProperties.AutomationId="RpfToFivem.LogBox" MinHeight="170" MaxHeight="360" AcceptsReturn="True" TextWrapping="NoWrap" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" IsReadOnly="True" Text="等待任务输出..."/></StackPanel>
    </Border>
  </StackPanel>
</ScrollViewer>
"@

    $root = Import-CkXaml $xaml
    $ui = Get-CkNamedControls -Root $root -Names @(
        'EnvironmentStatus','PythonDot','PythonText','PythonDownloadButton','PythonBrowseButton','DotNetDot','DotNetText','DotNetButton','ComponentDot','ComponentText',
        'InputBox','ChooseFileButton','ChooseFolderButton','OutputBox','ChooseOutputButton','OpenOutputButton',
        'TimeoutBox','DepthBox','ArchivesBox','ArchiveFilesBox','UnpackedGbBox','OverwriteBox','KeepWorkBox','StartButton','StopButton',
        'ResultStatus','OpenReportButton','RpfCount','SuccessCount','FailedCount','OutputFileCount','WarningCount','ProgressBar','StatusLine',
        'ResourceCounter','ResourceList','LogBox'
    )
    $ui.InputBox.Text = [string]$Context.Paths.DefaultRpfInput
    $ui.OutputBox.Text = [string]$Context.Paths.DefaultRpfOutput
    $ui.ResourceList.ItemsSource = $rows

    function Get-RpfPythonInfo {
        $environment = Get-CkToolboxEnvironment -Context $Context
        $blender = if ($environment.Blender.Ok) { $environment.Blender.Path } else { '' }
        $settings = Get-CkDependencySettings
        return Get-CkPythonInfo -RuntimeRoot $Context.Paths.RuntimeRoot -BlenderExe $blender -ConfiguredPath ([string]$settings.PythonPath)
    }

    function Get-RpfPython {
        $info = & $getPythonInfoAction
        if (-not $info.Ok) { throw [string]$info.Reason }
        return [string]$info.Path
    }

    function Update-RpfEnvironment {
        $scriptOk = Test-Path -LiteralPath $Context.Paths.RpfToFivemScript -PathType Leaf
        $extractorOk = Test-Path -LiteralPath (Join-Path $Context.Paths.RpfToFivemDir 'tools\CkRpfExtractor.exe') -PathType Leaf
        $archiveOk = Test-Path -LiteralPath (Join-Path $Context.Paths.RpfToFivemDir 'tools\7z.exe') -PathType Leaf
        $environment = Get-CkToolboxEnvironment -Context $Context
        $pythonInfo = & $getPythonInfoAction
        $pythonOk = [bool]$pythonInfo.Ok
        $componentOk = $scriptOk -and $extractorOk -and $archiveOk
        Set-CkStatusDot $ui.PythonDot $pythonOk
        Set-CkStatusDot $ui.DotNetDot $environment.DotNet.Ok
        Set-CkStatusDot $ui.ComponentDot $componentOk
        $ui.PythonText.Text = [string]$pythonInfo.Label
        $ui.PythonText.ToolTip = if ($pythonOk) { [string]$pythonInfo.Path } else { [string]$pythonInfo.Reason }
        $ui.PythonDownloadButton.Visibility = if ($pythonOk) { 'Collapsed' } else { 'Visible' }
        $ui.PythonBrowseButton.Content = if ($pythonOk) { '更改' } else { '选择' }
        $ui.DotNetText.Text = $environment.DotNet.Label
        $ui.ComponentText.Text = if ($componentOk) { '提取器与 7-Zip 已就绪' } else { '请在顶部安装组件' }
        $allOk = $pythonOk -and $environment.DotNet.Ok -and $componentOk
        $ui.EnvironmentStatus.Text = if ($allOk) { '运行环境就绪' } else { '请处理缺失项' }
        $ui.EnvironmentStatus.Foreground = if ($allOk) { '#31D69A' } else { '#F4B860' }
    }

    function Set-RpfRunning {
        param([bool]$Running)
        foreach ($control in @($ui.InputBox,$ui.ChooseFileButton,$ui.ChooseFolderButton,$ui.OutputBox,$ui.ChooseOutputButton,$ui.TimeoutBox,$ui.DepthBox,$ui.ArchivesBox,$ui.ArchiveFilesBox,$ui.UnpackedGbBox,$ui.OverwriteBox,$ui.KeepWorkBox,$ui.PythonDownloadButton,$ui.PythonBrowseButton,$ui.StartButton)) {
            $control.IsEnabled = -not $Running
        }
        $ui.StopButton.IsEnabled = $Running
        $ui.ProgressBar.IsIndeterminate = $Running
        if ($Running) {
            $ui.ProgressBar.Value = 10
            $ui.ResultStatus.Text = '正在转换'
            $ui.ResultStatus.Foreground = '#72B7F2'
            $ui.StatusLine.Text = '正在扫描输入、解压并转换 RPF，可随时停止。'
        } else {
            $ui.ProgressBar.IsIndeterminate = $false
        }
    }
    function Get-RpfSummaryValue {
        param($Summary, [string]$Name)
        if ($Summary -and $Summary.PSObject.Properties[$Name]) { return [int]$Summary.$Name }
        return 0
    }

    function Get-RpfInteger {
        param($Box, [string]$Label, [int]$Minimum, [int]$Maximum)
        [int]$value = 0
        if (-not [int]::TryParse($Box.Text.Trim(), [ref]$value) -or $value -lt $Minimum -or $value -gt $Maximum) {
            throw "$Label 必须在 $Minimum 到 $Maximum 之间。"
        }
        return $value
    }

    function Show-RpfResult {
        param($Payload, [int]$ExitCode)

        $resources = @($Payload.resources)
        $summary = $Payload.summary
        $found = & $getSummaryValueAction $summary 'rpf_found'
        $succeeded = & $getSummaryValueAction $summary 'succeeded'
        $failed = & $getSummaryValueAction $summary 'failed'
        $outputFiles = 0
        $warningCount = @($Payload.archive_failures).Count
        foreach ($item in $resources) {
            if ($item.output_files) { $outputFiles += [int]$item.output_files }
            $warningCount += @($item.warnings).Count
        }

        $ui.RpfCount.Text = [string]$found
        $ui.SuccessCount.Text = [string]$succeeded
        $ui.FailedCount.Text = [string]$failed
        $ui.OutputFileCount.Text = [string]$outputFiles
        $ui.WarningCount.Text = [string]$warningCount
        $ui.ProgressBar.Value = 100
        $rows.Clear()
        foreach ($item in $resources) {
            $ok = [string]$item.status -eq 'success'
            $warnings = @($item.warnings).Count
            $detail = if ($item.error) { [string]$item.error } elseif ($item.output) { [string]$item.output } else { [string]$item.relative_hint }
            [void]$rows.Add([pscustomobject]@{
                Status = $(if ($ok) { '转换成功' } else { '转换失败' })
                StatusColor = $(if ($ok) { '#31D69A' } else { '#EF7C86' })
                Name = [string]$item.resource_name
                Detail = $detail
                FilesText = "$([int]$item.output_files) 文件"
                WarningsText = $(if ($warnings) { "$warnings 警告" } else { '-' })
            })
        }
        $ui.ResourceCounter.Text = "$($resources.Count) 项"

        $reportPath = if ($Payload.report) { [string]$Payload.report } else { Join-Path ([string]$Payload.output) '_rpf_to_fivem_report.json' }
        $state.ReportPath = $reportPath
        $ui.OpenReportButton.IsEnabled = $reportPath -and (Test-Path -LiteralPath $reportPath -PathType Leaf)

        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add("工具版本: $($Payload.version)")
        $lines.Add("输入: $($Payload.input)")
        $lines.Add("输出: $($Payload.output)")
        $lines.Add("耗时: $($Payload.elapsed_seconds) 秒")
        $lines.Add("报告: $reportPath")
        $lines.Add('')
        foreach ($failure in @($Payload.archive_failures)) { $lines.Add("[压缩包失败] $failure") }
        foreach ($item in @($resources | Select-Object -First 200)) {
            $label = if ([string]$item.status -eq 'success') { '成功' } else { '失败' }
            $lines.Add("[$label] $($item.resource_name) | 输出文件 $([int]$item.output_files) | $($item.relative_hint)")
            if ($item.output) { $lines.Add("  -> $($item.output)") }
            if ($item.error) { $lines.Add("  错误: $($item.error)") }
            foreach ($warning in @($item.warnings)) { $lines.Add("  警告: $warning") }
            if (@($item.data_files).Count) { $lines.Add("  data_file: $(@($item.data_files).Count) 项") }
        }
        if ($resources.Count -gt 200) { $lines.Add("仅显示前 200 项日志，完整结果请打开报告。") }
        $ui.LogBox.Text = $lines -join [Environment]::NewLine
        $ui.LogBox.ScrollToHome()

        if ($found -eq 0) {
            $ui.ResultStatus.Text = '未发现 RPF'
            $ui.ResultStatus.Foreground = '#F4B860'
            $ui.StatusLine.Text = '输入中没有可处理的 RPF，请检查目录或压缩包。'
        } elseif ($failed -gt 0 -or $ExitCode -ne 0) {
            $ui.ResultStatus.Text = '完成，部分失败'
            $ui.ResultStatus.Foreground = '#F4B860'
            $ui.StatusLine.Text = "成功 $succeeded，失败 $failed；请查看资源明细。"
        } else {
            $ui.ResultStatus.Text = '转换完成'
            $ui.ResultStatus.Foreground = '#31D69A'
            $ui.StatusLine.Text = "已生成 $succeeded 个 FiveM resource，共 $outputFiles 个文件。"
        }
    }

    $getPythonInfoAction = (Get-Command Get-RpfPythonInfo).ScriptBlock.GetNewClosure()
    $getPythonAction = (Get-Command Get-RpfPython).ScriptBlock.GetNewClosure()
    $updateEnvironmentAction = (Get-Command Update-RpfEnvironment).ScriptBlock.GetNewClosure()
    $setRunningAction = (Get-Command Set-RpfRunning).ScriptBlock.GetNewClosure()
    $getSummaryValueAction = (Get-Command Get-RpfSummaryValue).ScriptBlock.GetNewClosure()
    $getIntegerAction = (Get-Command Get-RpfInteger).ScriptBlock.GetNewClosure()
    $showResultAction = (Get-Command Show-RpfResult).ScriptBlock.GetNewClosure()

    $showPageError = {
        param([string]$message)
        $ui.ResultStatus.Text = '操作失败'
        $ui.ResultStatus.Foreground = '#EF7C86'
        $ui.StatusLine.Text = $message
        Add-CkLogLine -TextBox $ui.LogBox -Line "[工具箱] $message"
        [System.Windows.MessageBox]::Show($message, 'CK免费工具箱 - RPF 转 FiveM') | Out-Null
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

    $chooseFileAction = {
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = '选择 RPF 或压缩包'
        $dialog.Filter = 'RPF 与压缩包|*.rpf;*.zip;*.rar;*.7z;*.tar;*.gz;*.tgz;*.bz2;*.tbz2;*.xz;*.txz|所有文件|*.*'
        $dialog.Multiselect = $false
        if (Test-Path -LiteralPath $ui.InputBox.Text.Trim() -PathType Container) { $dialog.InitialDirectory = $ui.InputBox.Text.Trim() }
        try { if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $ui.InputBox.Text = $dialog.FileName } } finally { $dialog.Dispose() }
    }.GetNewClosure()

    $chooseFolderAction = {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = '选择包含 RPF 或压缩包的目录'
        $dialog.SelectedPath = $ui.InputBox.Text.Trim()
        $dialog.ShowNewFolderButton = $false
        try { if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $ui.InputBox.Text = $dialog.SelectedPath } } finally { $dialog.Dispose() }
    }.GetNewClosure()

    $chooseOutputAction = {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = '选择 FiveM 资源输出目录'
        $dialog.SelectedPath = $ui.OutputBox.Text.Trim()
        $dialog.ShowNewFolderButton = $true
        try { if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $ui.OutputBox.Text = $dialog.SelectedPath } } finally { $dialog.Dispose() }
    }.GetNewClosure()

    $openOutputAction = {
        $path = $ui.OutputBox.Text.Trim()
        if (-not (Test-Path -LiteralPath $path -PathType Container)) { throw "输出目录不存在: $path" }
        Start-Process -FilePath explorer.exe -ArgumentList @($path)
    }.GetNewClosure()

    $openReportAction = {
        $path = [string]$state.ReportPath
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "转换报告不存在: $path" }
        Start-Process -FilePath $path
    }.GetNewClosure()

    $openDotNetAction = {
        Start-Process -FilePath 'https://dotnet.microsoft.com/download/dotnet-framework/net48'
    }.GetNewClosure()

    function Start-RpfConversion {
        if ($state.Process -and -not $state.Process.Process.HasExited) { throw '已有 RPF 转换任务正在运行。' }
        if (-not (Test-Path -LiteralPath $Context.Paths.RpfToFivemScript -PathType Leaf)) { throw 'RPF 组件未安装，请先点击顶部“安装组件”。' }
        $extractor = Join-Path $Context.Paths.RpfToFivemDir 'tools\CkRpfExtractor.exe'
        $archiveTool = Join-Path $Context.Paths.RpfToFivemDir 'tools\7z.exe'
        if (-not (Test-Path -LiteralPath $extractor -PathType Leaf) -or -not (Test-Path -LiteralPath $archiveTool -PathType Leaf)) { throw 'RPF 组件不完整，请在顶部重新安装组件。' }

        $inputPath = $ui.InputBox.Text.Trim()
        if (-not $inputPath -or -not (Test-Path -LiteralPath $inputPath)) { throw '请选择存在的输入目录、RPF 或压缩包。' }
        $inputPath = [IO.Path]::GetFullPath($inputPath).TrimEnd('\')
        if (Test-Path -LiteralPath $inputPath -PathType Leaf) {
            $allowed = @('.rpf','.zip','.rar','.7z','.tar','.gz','.tgz','.bz2','.tbz2','.xz','.txz')
            if ([IO.Path]::GetExtension($inputPath).ToLowerInvariant() -notin $allowed) { throw '输入文件必须是 RPF 或受支持的压缩包。' }
        } else {
            $driveRoot = [IO.Path]::GetPathRoot($inputPath).TrimEnd('\')
            if ($inputPath.Equals($driveRoot, [StringComparison]::OrdinalIgnoreCase)) { throw '不能扫描整个磁盘，请选择具体目录。' }
        }

        $outputPath = $ui.OutputBox.Text.Trim()
        if (-not $outputPath) { throw '请选择输出目录。' }
        $outputPath = [IO.Path]::GetFullPath($outputPath).TrimEnd('\')
        if ((Test-Path -LiteralPath $inputPath -PathType Container) -and $inputPath.Equals($outputPath, [StringComparison]::OrdinalIgnoreCase)) { throw '输入目录和输出目录不能相同。' }
        $outputRoot = [IO.Path]::GetPathRoot($outputPath).TrimEnd('\')
        if ($outputPath.Equals($outputRoot, [StringComparison]::OrdinalIgnoreCase)) { throw '不能直接输出到磁盘根目录。' }

        $timeout = & $getIntegerAction $ui.TimeoutBox '单次超时' 1 86400
        $depth = & $getIntegerAction $ui.DepthBox '嵌套压缩层数' 0 20
        $archives = & $getIntegerAction $ui.ArchivesBox '压缩包数量上限' 1 10000
        $archiveFiles = & $getIntegerAction $ui.ArchiveFilesBox '单包文件数上限' 1 2000000
        [double]$unpackedGb = 0
        if (-not [double]::TryParse($ui.UnpackedGbBox.Text.Trim(), [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$unpackedGb) -or $unpackedGb -le 0 -or $unpackedGb -gt 1024) { throw '单包解压上限必须在 0 到 1024 GB 之间。' }

        $environment = Get-CkToolboxEnvironment -Context $Context
        if (-not $environment.DotNet.Ok) { throw '需要先安装 .NET Framework 4.8。' }
        $python = & $getPythonAction
        if ($ui.OverwriteBox.IsChecked) {
            $answer = [System.Windows.MessageBox]::Show("已启用覆盖同名资源。转换器可能替换输出目录中的同名 resource。`n`n输出: $outputPath`n`n是否继续？", '确认覆盖转换', [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
            if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
        }

        $args = @('-u', $Context.Paths.RpfToFivemScript, $inputPath, $outputPath, '--extractor', $extractor, '--archive-tool', $archiveTool, '--timeout', [string]$timeout, '--max-archive-depth', [string]$depth, '--max-archives', [string]$archives, '--max-archive-files', [string]$archiveFiles, '--max-unpacked-gb', $unpackedGb.ToString([Globalization.CultureInfo]::InvariantCulture))
        if ($ui.OverwriteBox.IsChecked) { $args += '--overwrite' }
        if ($ui.KeepWorkBox.IsChecked) { $args += '--keep-work' }
        $args += '--json'

        $state.CancelRequested = $false
        $state.ReportPath = ''
        $rows.Clear()
        $ui.ResourceCounter.Text = '0 项'
        foreach ($counter in @($ui.RpfCount,$ui.SuccessCount,$ui.FailedCount,$ui.OutputFileCount,$ui.WarningCount)) { $counter.Text = '0' }
        $ui.OpenReportButton.IsEnabled = $false
        $ui.LogBox.Text = "开始转换...`r`n输入: $inputPath`r`n输出: $outputPath"
        & $setRunningAction $true

        $output = New-Object Text.StringBuilder
        $callbackOutput = $output
        $callbackState = $state
        $callbackUi = $ui
        $callbackOutputPath = $outputPath
        $callbackShowResult = $showResultAction
        $callbackSetRunning = $setRunningAction
        $onOutput = { param($line) [void]$callbackOutput.AppendLine($line) }.GetNewClosure()
        $onProcessError = { param($message) $callbackUi.StatusLine.Text = $message }.GetNewClosure()
        $onExit = {
            param($exitCode)
            $cancelled = $callbackState.CancelRequested
            $callbackState.CancelRequested = $false
            $callbackState.Process = $null
            & $callbackSetRunning $false
            if ($cancelled) {
                $callbackUi.ProgressBar.Value = 0
                $callbackUi.ResultStatus.Text = '任务已停止'
                $callbackUi.ResultStatus.Foreground = '#F4B860'
                $callbackUi.StatusLine.Text = '转换已由用户停止。已完成的 resource 不会自动删除。'
                Add-CkLogLine -TextBox $callbackUi.LogBox -Line '[工具箱] 任务已停止。'
                return
            }
            $raw = $callbackOutput.ToString().Trim()
            $payload = $null
            try { if ($raw) { $payload = $raw | ConvertFrom-Json } } catch { }
            if (-not $payload) {
                $lines = @($raw -split '\r?\n')
                for ($index = $lines.Count - 1; $index -ge 0 -and -not $payload; $index--) { try { $payload = $lines[$index] | ConvertFrom-Json } catch { } }
            }
            $reportCandidate = Join-Path $callbackOutputPath '_rpf_to_fivem_report.json'
            if (-not $payload -and (Test-Path -LiteralPath $reportCandidate -PathType Leaf)) { try { $payload = Get-Content -LiteralPath $reportCandidate -Raw -Encoding UTF8 | ConvertFrom-Json } catch { } }
            if ($payload) { & $callbackShowResult $payload $exitCode } else {
                $callbackUi.ProgressBar.Value = 94
                $callbackUi.ResultStatus.Text = '转换失败'
                $callbackUi.ResultStatus.Foreground = '#EF7C86'
                $callbackUi.StatusLine.Text = "进程退出码: $exitCode；转换器没有返回有效 JSON。"
                $callbackUi.LogBox.Text = if ($raw) { $raw } else { '转换器没有返回输出。' }
            }
        }.GetNewClosure()

        try { $state.Process = Start-CkLoggedProcess -FileName $python -Arguments $args -WorkingDirectory $Context.Paths.RpfToFivemDir -Dispatcher $Context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onProcessError } catch { & $setRunningAction $false; throw }
    }

    $startAction = (Get-Command Start-RpfConversion).ScriptBlock.GetNewClosure()
    $runAction = { & $startAction }.GetNewClosure()
    $stopAction = {
        if (-not $state.Process -or $state.Process.Process.HasExited) { return }
        $state.CancelRequested = $true
        $ui.StopButton.IsEnabled = $false
        $ui.ResultStatus.Text = '正在停止'
        $ui.StatusLine.Text = '正在停止 Python 与 RPF 提取子进程...'
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
        } catch { $state.CancelRequested = $false; throw "停止任务失败: $($_.Exception.Message)" }
    }.GetNewClosure()

    Register-CkButtonAction -Button $ui.PythonDownloadButton -Action $openPythonDownloadAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.PythonBrowseButton -Action $selectPythonAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseFileButton -Action $chooseFileAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseFolderButton -Action $chooseFolderAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseOutputButton -Action $chooseOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenOutputButton -Action $openOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenReportButton -Action $openReportAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.DotNetButton -Action $openDotNetAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StartButton -Action $runAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StopButton -Action $stopAction -OnError $showPageError

    & $updateEnvironmentAction
    return [pscustomobject]@{
        Id = 'rpf-to-fivem'
        Title = 'RPF 转 FiveM'
        Icon = '⇄'
        Root = $root
        Activate = $updateEnvironmentAction
    }
}