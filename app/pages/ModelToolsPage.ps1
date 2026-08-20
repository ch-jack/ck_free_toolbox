function New-CkModelToolsPage {
    param([Parameter(Mandatory)]$Context)

    $rows = New-Object System.Collections.ObjectModel.ObservableCollection[object]
    $state = [pscustomobject]@{
        Process = $null
        CancelRequested = $false
        Operation = ''
        ReportPath = ''
        OutputPath = ''
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
    <Style TargetType="{x:Type ComboBox}">
      <Setter Property="Foreground" Value="#111827"/>
      <Setter Property="Background" Value="#F4F7FB"/>
      <Setter Property="BorderBrush" Value="#596273"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="9,6"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="SnapsToDevicePixels" Value="True"/>
      <Style.Triggers>
        <Trigger Property="IsKeyboardFocusWithin" Value="True">
          <Setter Property="BorderBrush" Value="#58A6FF"/>
        </Trigger>
        <Trigger Property="IsEnabled" Value="False">
          <Setter Property="Foreground" Value="#4B5563"/>
          <Setter Property="Background" Value="#D7DCE3"/>
          <Setter Property="BorderBrush" Value="#8B95A3"/>
        </Trigger>
      </Style.Triggers>
    </Style>
    <Style TargetType="{x:Type ComboBoxItem}">
      <Setter Property="Foreground" Value="#F4F7FB"/>
      <Setter Property="Background" Value="#20242B"/>
      <Setter Property="BorderBrush" Value="#343A46"/>
      <Setter Property="BorderThickness" Value="0,0,0,1"/>
      <Setter Property="Padding" Value="10,8"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="SnapsToDevicePixels" Value="True"/>
      <Setter Property="OverridesDefaultStyle" Value="True"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="{x:Type ComboBoxItem}">
            <Border x:Name="ItemBorder"
                    Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    Padding="{TemplateBinding Padding}"
                    SnapsToDevicePixels="True">
              <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"
                                VerticalAlignment="{TemplateBinding VerticalContentAlignment}"
                                SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsHighlighted" Value="True">
                <Setter TargetName="ItemBorder" Property="Background" Value="#315A91"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
              </Trigger>
              <Trigger Property="IsSelected" Value="True">
                <Setter TargetName="ItemBorder" Property="Background" Value="#173055"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="ItemBorder" Property="Background" Value="#191C21"/>
                <Setter TargetName="ItemBorder" Property="BorderBrush" Value="#2A2E37"/>
                <Setter Property="Foreground" Value="#8F98A5"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </ScrollViewer.Resources>
  <StackPanel>
    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12">
          <StackPanel Orientation="Horizontal">
            <Border Width="4" Height="22" CornerRadius="3" Background="#A99CFF" Margin="0,0,10,0"/>
            <StackPanel>
              <TextBlock Text="载具 / 武器 / 声浪资源提取" FontSize="21" FontWeight="Bold"/>
              <TextBlock Text="递归识别 FiveM resource 中的模型和声浪，并按完整资源文件夹列清单或复制" Foreground="#777B83" FontSize="12" Margin="0,4,0,0"/>
            </StackPanel>
          </StackPanel>
          <TextBlock x:Name="EnvironmentStatus" AutomationProperties.AutomationId="ModelTools.EnvironmentStatus" Text="检测中" HorizontalAlignment="Right" VerticalAlignment="Center" Foreground="#F4B860" FontSize="14" FontWeight="SemiBold"/>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Border Grid.Column="0" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="0,0,5,0">
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/><ColumnDefinition Width="94"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="PythonDot" Width="9" Height="9" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1"><TextBlock Text="Python 3.7+" FontSize="14" FontWeight="SemiBold"/><TextBlock x:Name="PythonText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel>
              <StackPanel Grid.Column="2" Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="PythonDownloadButton" AutomationProperties.AutomationId="ModelTools.PythonDownloadButton" Content="官网" Width="42" Height="27" Margin="0,0,5,0" Foreground="#58A6FF" Visibility="Collapsed"/>
                <Button x:Name="PythonBrowseButton" AutomationProperties.AutomationId="ModelTools.PythonBrowseButton" Content="选择" Width="42" Height="27"/>
              </StackPanel>
            </Grid>
          </Border>
          <Border Grid.Column="1" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="5,0,0,0">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Ellipse x:Name="ComponentDot" Width="9" Height="9" Fill="#31D69A" VerticalAlignment="Center"/><StackPanel Grid.Column="1"><TextBlock Text="识别与复制组件" FontSize="14" FontWeight="SemiBold"/><TextBlock x:Name="ComponentText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel></Grid>
          </Border>
        </Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="输入与输出目录" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid Margin="0,0,0,10">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions>
          <StackPanel><TextBlock Text="FiveM resources 根目录或单个 resource 目录" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="InputBox" AutomationProperties.AutomationId="ModelTools.InputBox" Height="36"/></StackPanel>
          <Button x:Name="ChooseInputButton" AutomationProperties.AutomationId="ModelTools.ChooseInputButton" Grid.Column="1" Content="选择输入" Height="36" Margin="7,22,0,0" Background="#173055" Foreground="#58A6FF"/>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions>
          <StackPanel><TextBlock Text="完整资源复制输出目录" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="OutputBox" AutomationProperties.AutomationId="ModelTools.OutputBox" Height="36"/></StackPanel>
          <Button x:Name="ChooseOutputButton" AutomationProperties.AutomationId="ModelTools.ChooseOutputButton" Grid.Column="1" Content="选择输出" Height="36" Margin="7,22,0,0" Background="#173055" Foreground="#58A6FF"/>
          <Button x:Name="OpenOutputButton" AutomationProperties.AutomationId="ModelTools.OpenOutputButton" Grid.Column="2" Content="打开输出" Height="36" Margin="7,22,0,0"/>
        </Grid>
        <CheckBox x:Name="AutoOpenBox" AutomationProperties.AutomationId="ModelTools.AutoOpenBox" Content="复制完成后自动打开输出目录" IsChecked="True" Margin="0,11,0,0"/>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="识别和复制选项" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid Margin="0,0,0,12">
          <Grid.ColumnDefinitions><ColumnDefinition Width="0.7*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <StackPanel Grid.Column="0" Margin="0,0,10,0">
            <TextBlock Text="资源类型" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/>
            <ComboBox x:Name="TypeBox" AutomationProperties.AutomationId="ModelTools.TypeBox" Height="35" SelectedIndex="0">
              <ComboBoxItem Content="全部类型" Tag="all"/>
              <ComboBoxItem Content="仅载具" Tag="vehicle"/>
              <ComboBoxItem Content="仅武器" Tag="weapon"/>
              <ComboBoxItem Content="仅声浪" Tag="sound"/>
            </ComboBox>
          </StackPanel>
          <CheckBox x:Name="IncludePossibleBox" AutomationProperties.AutomationId="ModelTools.IncludePossibleBox" Grid.Column="1" Content="复制疑似纯替换资源" Margin="10,22,10,0" ToolTip="清单始终显示疑似资源；勾选后复制操作也会包含它们。"/>
          <CheckBox x:Name="OverwriteBox" AutomationProperties.AutomationId="ModelTools.OverwriteBox" Grid.Column="2" Content="覆盖同名目标（先备份）" Margin="10,22,0,0"/>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions>
          <Button x:Name="ListButton" AutomationProperties.AutomationId="ModelTools.ListButton" Grid.Column="0" Content="列出资源清单" Height="44" Margin="0,0,7,0" Background="#173055" Foreground="#72B7F2" FontSize="15" FontWeight="Bold"/>
          <Button x:Name="CopyButton" AutomationProperties.AutomationId="ModelTools.CopyButton" Grid.Column="1" Content="复制完整资源文件夹" Height="44" Margin="7,0" Background="#124834" Foreground="#54E0A9" FontSize="15" FontWeight="Bold"/>
          <Button x:Name="StopButton" AutomationProperties.AutomationId="ModelTools.StopButton" Grid.Column="2" Content="停止任务" Height="44" Margin="7,0,0,0" Foreground="#F28B94" IsEnabled="False"/>
        </Grid>
        <TextBlock Text="清单操作不复制文件；复制操作不会拆分 stream、META、脚本或音频。默认不覆盖已有目标。" Foreground="#6E7580" FontSize="12" Margin="0,9,0,0" TextWrapping="Wrap"/>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12">
          <TextBlock Text="任务结果" FontSize="18" FontWeight="Bold"/>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right"><TextBlock x:Name="ResultStatus" AutomationProperties.AutomationId="ModelTools.ResultStatus" Text="等待任务" Foreground="#777B83" FontSize="13" VerticalAlignment="Center" Margin="0,0,10,0"/><Button x:Name="OpenReportButton" AutomationProperties.AutomationId="ModelTools.OpenReportButton" Content="打开本次报告" Height="28" IsEnabled="False"/></StackPanel>
        </Grid>
        <UniformGrid Columns="7" Margin="0,0,0,12">
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="0,0,4,0"><StackPanel><TextBlock Text="扫描资源" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="ScannedCount" Text="0" FontSize="19" FontWeight="Bold"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="载具" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="VehicleCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#72B7F2"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="武器" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="WeaponCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#A99CFF"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="声浪" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="SoundCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#76D7C4"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="混合" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="MixedCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#F4B860"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="疑似" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="PossibleCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#F4B860"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0,0,0"><StackPanel><TextBlock Text="已复制" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="CopiedCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#31D69A"/></StackPanel></Border>
        </UniformGrid>
        <ProgressBar x:Name="ProgressBar" AutomationProperties.AutomationId="ModelTools.ProgressBar" Height="8" Minimum="0" Maximum="100" Value="0"/>
        <TextBlock x:Name="StatusLine" AutomationProperties.AutomationId="ModelTools.StatusLine" Text="选择输入目录后列清单，确认结果后再复制。" Foreground="#8B9099" FontSize="13" Margin="0,9,0,0"/>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,10"><TextBlock Text="资源清单" FontSize="18" FontWeight="Bold"/><TextBlock x:Name="ResourceCounter" Text="0 项" HorizontalAlignment="Right" Foreground="#777B83" FontSize="12"/></Grid>
        <ListView x:Name="ResourceList" AutomationProperties.AutomationId="ModelTools.ResourceList" MinHeight="150" MaxHeight="330" Background="#0D0F11" Foreground="#F4F7FB" BorderBrush="#242833" BorderThickness="1" HorizontalContentAlignment="Stretch" VirtualizingStackPanel.IsVirtualizing="True" VirtualizingStackPanel.VirtualizationMode="Recycling" ScrollViewer.CanContentScroll="True" ScrollViewer.VerticalScrollBarVisibility="Visible" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
          <ListView.ItemContainerStyle>
            <Style TargetType="{x:Type ListViewItem}">
              <Setter Property="Foreground" Value="#F4F7FB"/>
              <Setter Property="Background" Value="Transparent"/>
              <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
              <Setter Property="Padding" Value="0"/>
            </Style>
          </ListView.ItemContainerStyle>
          <ListView.ItemTemplate><DataTemplate><Border BorderBrush="#20242C" BorderThickness="0,0,0,1" Padding="9"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="118"/><ColumnDefinition Width="82"/><ColumnDefinition Width="*"/><ColumnDefinition Width="105"/></Grid.ColumnDefinitions><TextBlock Text="{Binding TypeText}" Foreground="{Binding TypeColor}" FontWeight="SemiBold"/><TextBlock Grid.Column="1" Text="{Binding ConfidenceText}" Foreground="{Binding ConfidenceColor}"/><StackPanel Grid.Column="2"><TextBlock Text="{Binding Path}" Foreground="#F4F7FB" FontSize="13" FontWeight="SemiBold"/><TextBlock Text="{Binding Detail}" Foreground="#AAB2BE" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel><TextBlock Grid.Column="3" Text="{Binding StatusText}" Foreground="{Binding StatusColor}" VerticalAlignment="Center" TextAlignment="Right"/></Grid></Border></DataTemplate></ListView.ItemTemplate>
        </ListView>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16">
      <StackPanel><TextBlock Text="任务日志" FontSize="18" FontWeight="Bold" Margin="0,0,0,9"/><TextBox x:Name="LogBox" AutomationProperties.AutomationId="ModelTools.LogBox" MinHeight="160" MaxHeight="340" AcceptsReturn="True" TextWrapping="NoWrap" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" IsReadOnly="True" Text="等待任务输出..."/></StackPanel>
    </Border>
  </StackPanel>
</ScrollViewer>
"@

    $root = Import-CkXaml $xaml
    $ui = Get-CkNamedControls -Root $root -Names @(
        'EnvironmentStatus','PythonDot','PythonText','PythonDownloadButton','PythonBrowseButton','ComponentDot','ComponentText',
        'InputBox','ChooseInputButton','OutputBox','ChooseOutputButton','OpenOutputButton','AutoOpenBox',
        'TypeBox','IncludePossibleBox','OverwriteBox','ListButton','CopyButton','StopButton',
        'ResultStatus','OpenReportButton','ScannedCount','VehicleCount','WeaponCount','SoundCount','MixedCount','PossibleCount','CopiedCount',
        'ProgressBar','StatusLine','ResourceCounter','ResourceList','LogBox'
    )
    $ui.InputBox.Text = [string]$Context.Paths.DefaultModelToolsInput
    $ui.OutputBox.Text = [string]$Context.Paths.DefaultModelToolsOutput
    $ui.ResourceList.ItemsSource = $rows

    function Get-ModelToolsPythonInfo {
        $environment = Get-CkToolboxEnvironment -Context $Context
        $blender = if ($environment.Blender.Ok) { $environment.Blender.Path } else { '' }
        $settings = Get-CkDependencySettings
        return Get-CkPythonInfo -RuntimeRoot $Context.Paths.RuntimeRoot -BlenderExe $blender -ConfiguredPath ([string]$settings.PythonPath)
    }

    function Get-ModelToolsPython {
        $info = & $getPythonInfoAction
        if (-not $info.Ok) { throw [string]$info.Reason }
        return [string]$info.Path
    }

    function Get-ModelToolsProperty {
        param($Object, [string]$Name, $Default = $null)
        if ($Object -and $Object.PSObject.Properties[$Name]) { return $Object.$Name }
        return $Default
    }

    function Get-ModelToolsInt {
        param($Object, [string]$Name)
        return [int](& $getPropertyAction $Object $Name 0)
    }

    function Get-ModelToolsScrollViewer {
        param([Parameter(Mandatory)][System.Windows.DependencyObject]$Element)

        $queue = New-Object System.Collections.Queue
        $queue.Enqueue($Element)
        while ($queue.Count -gt 0) {
            $current = [System.Windows.DependencyObject]$queue.Dequeue()
            if ($current -is [System.Windows.Controls.ScrollViewer]) { return $current }
            $childCount = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($current)
            for ($index = 0; $index -lt $childCount; $index++) {
                $queue.Enqueue([System.Windows.Media.VisualTreeHelper]::GetChild($current, $index))
            }
        }
        return $null
    }

    function Update-ModelToolsEnvironment {
        $pythonInfo = & $getPythonInfoAction
        $pythonOk = [bool]$pythonInfo.Ok
        $componentOk = Test-Path -LiteralPath $Context.Paths.ModelToolsScript -PathType Leaf
        Set-CkStatusDot $ui.PythonDot $pythonOk
        Set-CkStatusDot $ui.ComponentDot $componentOk
        $ui.PythonText.Text = [string]$pythonInfo.Label
        $ui.PythonText.ToolTip = if ($pythonOk) { [string]$pythonInfo.Path } else { [string]$pythonInfo.Reason }
        $ui.PythonDownloadButton.Visibility = if ($pythonOk) { 'Collapsed' } else { 'Visible' }
        $ui.PythonBrowseButton.Content = if ($pythonOk) { '更改' } else { '选择' }
        $ui.ComponentText.Text = if ($componentOk) { 'list / copy 组件已就绪' } else { '请在顶部安装组件' }
        $allOk = $pythonOk -and $componentOk
        $ui.EnvironmentStatus.Text = if ($allOk) { '运行环境就绪' } else { '请处理缺失项' }
        $ui.EnvironmentStatus.Foreground = if ($allOk) { '#31D69A' } else { '#F4B860' }
    }

    function Set-ModelToolsRunning {
        param([bool]$Running, [string]$Label = '')
        foreach ($control in @($ui.InputBox,$ui.ChooseInputButton,$ui.OutputBox,$ui.ChooseOutputButton,$ui.AutoOpenBox,$ui.TypeBox,$ui.IncludePossibleBox,$ui.OverwriteBox,$ui.ListButton,$ui.CopyButton,$ui.PythonDownloadButton,$ui.PythonBrowseButton)) {
            $control.IsEnabled = -not $Running
        }
        $ui.StopButton.IsEnabled = $Running
        $ui.ProgressBar.IsIndeterminate = $Running
        if ($Running) {
            $ui.ResultStatus.Text = $Label
            $ui.ResultStatus.Foreground = '#72B7F2'
            $ui.StatusLine.Text = '正在纯静态扫描资源；不会执行输入目录中的任何代码。'
            $ui.ProgressBar.Value = 8
        } else {
            $ui.ProgressBar.IsIndeterminate = $false
        }
    }

    function Get-ModelToolsTypeSelection {
        $item = $ui.TypeBox.SelectedItem
        if ($item -and $item.PSObject.Properties['Tag']) { return [string]$item.Tag }
        return 'all'
    }

    function New-ModelToolsReportPaths {
        param([string]$Operation)
        $base = Join-Path (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CKFreeToolbox') 'fivem-model-tools-reports'
        $run = (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + $Operation + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 6)
        $directory = Join-Path $base $run
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        return [pscustomobject]@{
            Json = Join-Path $directory 'report.json'
            Html = Join-Path $directory 'report.html'
        }
    }

    function Show-ModelToolsResult {
        param($Payload, [int]$ExitCode)
        $summary = & $getPropertyAction $Payload 'summary' $null
        $ui.ScannedCount.Text = [string](& $getIntAction $summary 'resources_scanned')
        $ui.VehicleCount.Text = [string](& $getIntAction $summary 'vehicle')
        $ui.WeaponCount.Text = [string](& $getIntAction $summary 'weapon')
        $ui.SoundCount.Text = [string](& $getIntAction $summary 'sound')
        $ui.MixedCount.Text = [string](& $getIntAction $summary 'mixed')
        $ui.PossibleCount.Text = [string](& $getIntAction $summary 'possible')
        $ui.CopiedCount.Text = [string](& $getIntAction $summary 'copied')
        $reportPath = [string](& $getPropertyAction $Payload 'html_report' '')
        if (-not $reportPath) { $reportPath = [string](& $getPropertyAction $Payload 'report' '') }
        if (-not $reportPath) { $reportPath = [string]$state.ReportPath }
        $state.ReportPath = if ($reportPath -and (Test-Path -LiteralPath $reportPath -PathType Leaf)) { [IO.Path]::GetFullPath($reportPath) } else { '' }
        $ui.OpenReportButton.IsEnabled = [bool]$state.ReportPath

        $rows.Clear()
        $logLines = New-Object System.Collections.Generic.List[string]
        $logLines.Add("操作: $($state.Operation)")
        $logLines.Add("输入: $([string](& $getPropertyAction $Payload 'source' ''))")
        $destination = [string](& $getPropertyAction $Payload 'destination' '')
        if ($destination) { $logLines.Add("输出: $destination") }
        if ($state.ReportPath) { $logLines.Add("HTML 报告: $($state.ReportPath)") }
        $jsonReportPath = [string](& $getPropertyAction $Payload 'json_report' '')
        if ($jsonReportPath) { $logLines.Add("JSON 数据: $jsonReportPath") }
        $copyInfo = & $getPropertyAction $Payload 'copy' $null
        $backupRoot = [string](& $getPropertyAction $copyInfo 'backup_root' '')
        if ($backupRoot) { $logLines.Add("备份: $backupRoot") }
        $logLines.Add('')

        foreach ($item in @(& $getPropertyAction $Payload 'resources' @())) {
            $kind = [string](& $getPropertyAction $item 'classification' 'unknown')
            $confidence = [string](& $getPropertyAction $item 'confidence' 'unknown')
            $status = [string](& $getPropertyAction $item 'status' 'listed')
            $typeValues = @(& $getPropertyAction $item 'types' @())
            $typeText = switch ($kind) {
                'vehicle' { '载具' }
                'weapon' { '武器' }
                'sound' { '声浪' }
                'mixed' {
                    $parts = @()
                    if ($typeValues -contains 'vehicle') { $parts += '载具' }
                    if ($typeValues -contains 'weapon') { $parts += '武器' }
                    if ($typeValues -contains 'sound') { $parts += '声浪' }
                    if ($parts.Count) { $parts -join '+' } else { '混合' }
                }
                default { '未知' }
            }
            $typeColor = switch ($kind) { 'vehicle' { '#72B7F2' } 'weapon' { '#A99CFF' } 'sound' { '#76D7C4' } 'mixed' { '#F4B860' } default { '#777B83' } }
            $confidenceText = switch ($confidence) { 'confirmed' { '已确认' } 'possible' { '疑似' } 'partial' { '部分确认' } default { '未知' } }
            $confidenceColor = if ($confidence -eq 'confirmed') { '#31D69A' } else { '#F4B860' }
            $statusText = switch ($status) {
                'listed' { '已列出' }
                'copied' { '已复制' }
                'skipped_exists' { '已存在，跳过' }
                'not_selected_possible' { '疑似未复制' }
                'covered_by_parent' { '父目录已包含' }
                'blocked' { '安全阻止' }
                'failed' { '失败' }
                default { $status }
            }
            $statusColor = switch ($status) { 'copied' { '#31D69A' } 'failed' { '#EF7C86' } 'blocked' { '#EF7C86' } 'skipped_exists' { '#F4B860' } default { '#8B9099' } }
            $reasons = @(& $getPropertyAction $item 'reasons' @()) -join '; '
            $warnings = @(& $getPropertyAction $item 'warnings' @()) -join '; '
            $errorText = [string](& $getPropertyAction $item 'error' '')
            $detailParts = @($reasons, $warnings, $errorText) | Where-Object { $_ }
            $detail = $detailParts -join ' · '
            $path = [string](& $getPropertyAction $item 'relative_path' '')
            $rows.Add([pscustomobject]@{
                TypeText = $typeText
                TypeColor = $typeColor
                ConfidenceText = $confidenceText
                ConfidenceColor = $confidenceColor
                Path = $path
                Detail = $detail
                StatusText = $statusText
                StatusColor = $statusColor
            })
            $logLines.Add("[$typeText/$confidenceText/$statusText] $path")
            if ($reasons) { $logLines.Add("  $reasons") }
            if ($warnings) { $logLines.Add("  警告: $warnings") }
            if ($errorText) { $logLines.Add("  错误: $errorText") }
            $itemBackup = [string](& $getPropertyAction $item 'backup_path' '')
            if ($itemBackup) { $logLines.Add("  备份: $itemBackup") }
        }
        foreach ($message in @(& $getPropertyAction $Payload 'errors' @())) { $logLines.Add("[错误] $message") }
        $ui.ResourceCounter.Text = "$($rows.Count) 项"
        $ui.LogBox.Text = $logLines -join [Environment]::NewLine
        $ui.LogBox.ScrollToHome()
        $failed = & $getIntAction $summary 'failed'
        $blocked = & $getIntAction $summary 'blocked'
        $matched = & $getIntAction $summary 'matched'
        $copied = & $getIntAction $summary 'copied'
        if ($ExitCode -eq 0) {
            $ui.ResultStatus.Text = if ($state.Operation -eq 'copy') { '复制任务完成' } else { '清单已生成' }
            $ui.ResultStatus.Foreground = '#31D69A'
            $ui.StatusLine.Text = if ($matched -eq 0) { '没有识别到符合筛选条件的载具、武器或声浪资源。' } elseif ($state.Operation -eq 'copy') { "已复制 $copied 个资源；请检查跳过项和报告。" } else { "已列出 $matched 个资源；清单没有复制文件。" }
            $ui.ProgressBar.Value = 100
        } else {
            $ui.ResultStatus.Text = '任务存在错误'
            $ui.ResultStatus.Foreground = '#EF7C86'
            $ui.StatusLine.Text = "失败 $failed，安全阻止 $blocked；请查看本次报告。"
            $ui.ProgressBar.Value = 96
        }
    }

    $getPythonInfoAction = (Get-Command Get-ModelToolsPythonInfo).ScriptBlock.GetNewClosure()
    $getPythonAction = (Get-Command Get-ModelToolsPython).ScriptBlock.GetNewClosure()
    $getPropertyAction = (Get-Command Get-ModelToolsProperty).ScriptBlock.GetNewClosure()
    $getIntAction = (Get-Command Get-ModelToolsInt).ScriptBlock.GetNewClosure()
    $getScrollViewerAction = (Get-Command Get-ModelToolsScrollViewer).ScriptBlock.GetNewClosure()
    $updateEnvironmentAction = (Get-Command Update-ModelToolsEnvironment).ScriptBlock.GetNewClosure()
    $setRunningAction = (Get-Command Set-ModelToolsRunning).ScriptBlock.GetNewClosure()
    $getTypeAction = (Get-Command Get-ModelToolsTypeSelection).ScriptBlock.GetNewClosure()
    $newReportPathsAction = (Get-Command New-ModelToolsReportPaths).ScriptBlock.GetNewClosure()
    $showResultAction = (Get-Command Show-ModelToolsResult).ScriptBlock.GetNewClosure()

    $showPageError = {
        param([string]$message)
        $ui.ResultStatus.Text = '操作失败'
        $ui.ResultStatus.Foreground = '#EF7C86'
        $ui.StatusLine.Text = $message
        Add-CkLogLine -TextBox $ui.LogBox -Line "[工具箱] $message"
        [System.Windows.MessageBox]::Show($message, 'CK免费工具箱 - 载具武器声浪提取') | Out-Null
    }.GetNewClosure()

    $openPythonDownloadAction = { Start-Process -FilePath 'https://www.python.org/downloads/windows/' }.GetNewClosure()
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
        if ($dialog.ShowDialog() -ne $true) { return }
        $selected = [IO.Path]::GetFullPath($dialog.FileName)
        $info = Test-CkPythonExecutable -Path $selected
        if (-not $info.Ok) { throw [string]$info.Reason }
        [void](Set-CkDependencyPath -Dependency Python -Path $selected)
        & $updateEnvironmentAction
    }.GetNewClosure()

    $chooseFolderAction = {
        param($box, [string]$description)
        Add-Type -AssemblyName System.Windows.Forms
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = $description
        $dialog.ShowNewFolderButton = $true
        $current = $box.Text.Trim()
        if ($current -and (Test-Path -LiteralPath $current -PathType Container)) { $dialog.SelectedPath = [IO.Path]::GetFullPath($current) }
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $box.Text = $dialog.SelectedPath }
        $dialog.Dispose()
    }.GetNewClosure()
    $chooseInputAction = { & $chooseFolderAction $ui.InputBox '选择 FiveM resources 根目录或单个 resource 目录' }.GetNewClosure()
    $chooseOutputAction = { & $chooseFolderAction $ui.OutputBox '选择完整资源复制输出目录' }.GetNewClosure()
    $openOutputAction = {
        $path = $ui.OutputBox.Text.Trim()
        if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Container)) { throw '输出目录尚不存在。' }
        Start-Process -FilePath 'explorer.exe' -ArgumentList @([IO.Path]::GetFullPath($path))
    }.GetNewClosure()
    $openReportAction = {
        if (-not $state.ReportPath -or -not (Test-Path -LiteralPath $state.ReportPath -PathType Leaf)) { throw '本次报告不存在。' }
        Start-Process -FilePath $state.ReportPath
    }.GetNewClosure()

    function Start-ModelToolsOperation {
        param([ValidateSet('list','copy')][string]$Operation)
        if ($state.Process -and -not $state.Process.Process.HasExited) { throw '已有载具武器声浪任务正在运行。' }
        if (-not (Test-Path -LiteralPath $Context.Paths.ModelToolsScript -PathType Leaf)) { throw '组件未安装，请先点击顶部“安装组件”。' }
        $python = & $getPythonAction
        $inputPath = $ui.InputBox.Text.Trim()
        if (-not $inputPath -or -not (Test-Path -LiteralPath $inputPath -PathType Container)) { throw '请选择存在的输入目录。' }
        $inputPath = [IO.Path]::GetFullPath($inputPath)
        $outputPath = $ui.OutputBox.Text.Trim()
        if ($Operation -eq 'copy') {
            if (-not $outputPath) { throw '请选择输出目录。' }
            $outputPath = [IO.Path]::GetFullPath($outputPath)
            $detail = if ($ui.OverwriteBox.IsChecked) { '同名目标会先备份到输出目录之外，再替换。' } else { '同名目标会跳过，不会覆盖。' }
            $answer = [System.Windows.MessageBox]::Show(
                "即将把识别到的完整 resource 文件夹复制到：`n$outputPath`n`n$detail`n不会拆分或修改资源内部文件。是否继续？",
                '确认复制载具、武器和声浪资源',
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Information
            )
            if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
        }

        $reportPaths = & $newReportPathsAction $Operation
        $resourceType = & $getTypeAction
        $args = @('-u', $Context.Paths.ModelToolsScript, $Operation, $inputPath, '--type', $resourceType, '--json', '--progress', '--report', $reportPaths.Json, '--html-report', $reportPaths.Html)
        if ($Operation -eq 'copy') {
            $args += $outputPath
            if ($ui.IncludePossibleBox.IsChecked) { $args += '--include-possible' }
            if ($ui.OverwriteBox.IsChecked) { $args += '--overwrite' }
        }

        $state.Operation = $Operation
        $state.CancelRequested = $false
        $state.ReportPath = $reportPaths.Html
        $state.OutputPath = $outputPath
        $ui.OpenReportButton.IsEnabled = $false
        $ui.ProgressBar.Value = 0
        $ui.LogBox.Text = ''
        $rows.Clear()
        $ui.ResourceCounter.Text = '0 项'
        foreach ($counter in @($ui.ScannedCount,$ui.VehicleCount,$ui.WeaponCount,$ui.SoundCount,$ui.MixedCount,$ui.PossibleCount,$ui.CopiedCount)) { $counter.Text = '0' }
        & $setRunningAction $true $(if ($Operation -eq 'copy') { '正在扫描并复制' } else { '正在生成清单' })

        $output = New-Object Text.StringBuilder
        $callbackOutput = $output
        $callbackState = $state
        $callbackUi = $ui
        $callbackShowResult = $showResultAction
        $callbackSetRunning = $setRunningAction
        $callbackGetProperty = $getPropertyAction
        $callbackAutoOpen = [bool]$ui.AutoOpenBox.IsChecked
        $callbackOutputPath = $outputPath
        $onOutput = {
            param($line)
            if ($line -and $line.StartsWith('CK_PROGRESS ', [StringComparison]::Ordinal)) {
                $progress = $null
                try { $progress = $line.Substring(12) | ConvertFrom-Json } catch { }
                if ($progress) {
                    $phase = [string](& $callbackGetProperty $progress 'phase' '')
                    $completed = [int](& $callbackGetProperty $progress 'completed' 0)
                    $total = [int](& $callbackGetProperty $progress 'total' 0)
                    $percent = [double](& $callbackGetProperty $progress 'percent' 0)
                    $current = [string](& $callbackGetProperty $progress 'current' '')
                    if ($phase -eq 'discovering') {
                        $callbackUi.ProgressBar.IsIndeterminate = $true
                        $callbackUi.ResultStatus.Text = '正在发现 resources'
                        $callbackUi.StatusLine.Text = if ($current) { "已发现 $completed 个资源 · $current" } else { "已发现 $completed 个资源" }
                    } elseif ($phase -eq 'scanning') {
                        $callbackUi.ProgressBar.IsIndeterminate = $false
                        $callbackUi.ProgressBar.Value = [Math]::Min(82, [Math]::Max(1, $percent * 0.82))
                        $callbackUi.ResultStatus.Text = '正在识别载具和武器'
                        $callbackUi.StatusLine.Text = "已扫描 $completed / $total · $current"
                    } elseif ($phase -eq 'copying') {
                        $callbackUi.ProgressBar.IsIndeterminate = $false
                        $callbackUi.ProgressBar.Value = [Math]::Min(99, 82 + ($percent * 0.17))
                        $callbackUi.ResultStatus.Text = '正在复制完整资源'
                        $callbackUi.StatusLine.Text = "已处理 $completed / $total · $current"
                    }
                }
                return
            }
            [void]$callbackOutput.AppendLine($line)
        }.GetNewClosure()
        $onProcessError = { param($message) $callbackUi.StatusLine.Text = $message }.GetNewClosure()
        $onExit = {
            param($exitCode)
            $cancelled = $callbackState.CancelRequested
            $callbackState.CancelRequested = $false
            $callbackState.Process = $null
            & $callbackSetRunning $false
            $raw = $callbackOutput.ToString().Trim()
            $payload = $null
            try { if ($raw) { $payload = $raw | ConvertFrom-Json } } catch { }
            if (-not $payload) {
                $lines = @($raw -split '\r?\n')
                for ($index = $lines.Count - 1; $index -ge 0 -and -not $payload; $index--) { try { $payload = $lines[$index] | ConvertFrom-Json } catch { } }
            }
            if ($payload) {
                & $callbackShowResult $payload $exitCode
                $summary = & $callbackGetProperty $payload 'summary' $null
                $copied = [int](& $callbackGetProperty $summary 'copied' 0)
                if (-not $cancelled -and $exitCode -eq 0 -and $callbackState.Operation -eq 'copy' -and $callbackAutoOpen -and $copied -gt 0 -and (Test-Path -LiteralPath $callbackOutputPath -PathType Container)) {
                    Start-Process -FilePath 'explorer.exe' -ArgumentList @($callbackOutputPath)
                }
            } else {
                $callbackUi.ResultStatus.Text = if ($cancelled) { '任务已停止' } else { '结果解析失败' }
                $callbackUi.ResultStatus.Foreground = if ($cancelled) { '#F4B860' } else { '#EF7C86' }
                $callbackUi.StatusLine.Text = if ($cancelled) { '任务已由用户停止。' } else { "进程退出码: $exitCode" }
                $callbackUi.LogBox.Text = if ($raw) { $raw } else { '组件没有返回 JSON 结果。' }
                $callbackUi.OpenReportButton.IsEnabled = Test-Path -LiteralPath $callbackState.ReportPath -PathType Leaf
            }
        }.GetNewClosure()
        try {
            $state.Process = Start-CkLoggedProcess -FileName $python -Arguments $args -WorkingDirectory $Context.Paths.ModelToolsDir -Dispatcher $Context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onProcessError
        } catch {
            & $setRunningAction $false
            throw
        }
    }

    $startOperationAction = (Get-Command Start-ModelToolsOperation).ScriptBlock.GetNewClosure()
    $listAction = { & $startOperationAction 'list' }.GetNewClosure()
    $copyAction = { & $startOperationAction 'copy' }.GetNewClosure()
    $stopAction = {
        if (-not $state.Process -or $state.Process.Process.HasExited) { return }
        $state.CancelRequested = $true
        $ui.StopButton.IsEnabled = $false
        $ui.ResultStatus.Text = '正在停止'
        $ui.StatusLine.Text = '正在停止当前 Python 任务...'
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

    $resourceListMouseWheelAction = {
        param($sender, $eventArgs)
        $viewer = & $getScrollViewerAction $sender
        if (-not $viewer -or $viewer.ScrollableHeight -le 0) { return }
        $direction = if ($eventArgs.Delta -lt 0) { 1 } else { -1 }
        $targetOffset = [Math]::Max(0, [Math]::Min($viewer.ScrollableHeight, $viewer.VerticalOffset + (3 * $direction)))
        if ($targetOffset -ne $viewer.VerticalOffset) {
            $viewer.ScrollToVerticalOffset($targetOffset)
            $eventArgs.Handled = $true
        }
    }.GetNewClosure()
    $resourceListMouseWheelHandler = [System.Windows.Input.MouseWheelEventHandler]$resourceListMouseWheelAction
    $ui.ResourceList.AddHandler([System.Windows.UIElement]::MouseWheelEvent, $resourceListMouseWheelHandler, $true)

    Register-CkButtonAction -Button $ui.PythonDownloadButton -Action $openPythonDownloadAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.PythonBrowseButton -Action $selectPythonAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseInputButton -Action $chooseInputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseOutputButton -Action $chooseOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenOutputButton -Action $openOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenReportButton -Action $openReportAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ListButton -Action $listAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.CopyButton -Action $copyAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StopButton -Action $stopAction -OnError $showPageError

    & $updateEnvironmentAction
    return [pscustomobject]@{
        Id = 'fivem-model-tools'
        Title = '载具武器声浪'
        Icon = '▣'
        Root = $root
        Activate = $updateEnvironmentAction
    }
}
