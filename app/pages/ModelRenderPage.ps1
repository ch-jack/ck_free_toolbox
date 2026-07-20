function New-CkModelRenderPage {
    param([Parameter(Mandatory)]$Context)

    $rows = New-Object System.Collections.ObjectModel.ObservableCollection[object]
    $state = [pscustomobject][ordered]@{
        InputPath = $Context.Paths.DefaultInput
        OutputPath = $Context.Paths.DefaultRenderOut
        Process = $null
        StartedAt = $null
        Total = 0
        Done = 0
        Failed = 0
        ReportPath = ''
        ReportHistoryPath = ''
    }

    $xaml = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
              xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
              VerticalScrollBarVisibility="Auto" Padding="26,14,30,36">
  <ScrollViewer.Resources>
    <Style TargetType="ComboBox">
      <Setter Property="Foreground" Value="#111827"/>
      <Setter Property="Background" Value="#F8FAFC"/>
      <Setter Property="BorderBrush" Value="#6B7280"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="9,6"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
    <Style TargetType="ComboBoxItem">
      <Setter Property="Foreground" Value="#111827"/>
      <Setter Property="Background" Value="#F8FAFC"/>
      <Setter Property="Padding" Value="10,8"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Style.Triggers>
        <Trigger Property="IsHighlighted" Value="True">
          <Setter Property="Foreground" Value="#0F172A"/>
          <Setter Property="Background" Value="#DCE8F8"/>
        </Trigger>
        <Trigger Property="IsSelected" Value="True">
          <Setter Property="Foreground" Value="#0F172A"/>
          <Setter Property="Background" Value="#C9DCF5"/>
        </Trigger>
      </Style.Triggers>
    </Style>
  </ScrollViewer.Resources>
  <StackPanel>
    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="20">
      <StackPanel>
        <Grid Margin="0,0,0,14">
          <StackPanel Orientation="Horizontal">
            <Border Width="4" Height="22" CornerRadius="3" Background="#8A8F98" Margin="0,0,10,0"/>
            <TextBlock Text="环境依赖" FontSize="22" FontWeight="Bold"/>
          </StackPanel>
          <TextBlock x:Name="DependencyStatus" Text="检测中" HorizontalAlignment="Right" Foreground="#31D69A" FontSize="18" FontWeight="Bold"/>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>

          <Border Grid.Row="0" Grid.Column="0" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="12" Margin="0,0,6,6">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="20"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="BlenderDot" Width="10" Height="10" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1"><TextBlock Text="Blender" FontSize="16" FontWeight="SemiBold"/><TextBlock x:Name="BlenderText" Text="检测中..." Foreground="#777B83" FontSize="12" TextTrimming="CharacterEllipsis"/></StackPanel>
              <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="BlenderDownloadButton" AutomationProperties.AutomationId="ModelRender.BlenderDownloadButton" Content="官网" Width="48" Height="28" Margin="6,0,4,0" Foreground="#58A6FF"/>
                <Button x:Name="BlenderBrowseButton" AutomationProperties.AutomationId="ModelRender.BlenderBrowseButton" Content="选择" Width="48" Height="28"/>
              </StackPanel>
            </Grid>
          </Border>

          <Border Grid.Row="0" Grid.Column="1" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="12" Margin="6,0,0,6">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="20"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="CodeWalkerDot" Width="10" Height="10" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1"><TextBlock Text="CodeWalker" FontSize="16" FontWeight="SemiBold"/><TextBlock x:Name="CodeWalkerText" Text="检测中..." Foreground="#777B83" FontSize="12" TextTrimming="CharacterEllipsis"/></StackPanel>
              <TextBlock Grid.Column="2" Text="组件自带" Foreground="#31D69A" FontSize="12" VerticalAlignment="Center"/>
            </Grid>
          </Border>

          <Border Grid.Row="1" Grid.Column="0" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="12" Margin="0,6,6,6">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="20"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="DotNetDot" Width="10" Height="10" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1"><TextBlock Text=".NET 4.8" FontSize="16" FontWeight="SemiBold"/><TextBlock x:Name="DotNetText" Text="检测中..." Foreground="#777B83" FontSize="12" TextTrimming="CharacterEllipsis"/></StackPanel>
              <Button x:Name="DotNetDownloadButton" AutomationProperties.AutomationId="ModelRender.DotNetDownloadButton" Grid.Column="2" Content="官网" Width="52" Height="28" Margin="6,0,0,0" Foreground="#58A6FF"/>
            </Grid>
          </Border>

          <Border Grid.Row="1" Grid.Column="1" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="12" Margin="6,6,0,6">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="20"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="SollumzDot" Width="10" Height="10" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1"><TextBlock Text="Sollumz 插件" FontSize="16" FontWeight="SemiBold"/><TextBlock x:Name="SollumzText" Text="检测中..." Foreground="#777B83" FontSize="12" TextTrimming="CharacterEllipsis"/></StackPanel>
              <TextBlock Grid.Column="2" Text="组件自带" Foreground="#31D69A" FontSize="12" VerticalAlignment="Center"/>
            </Grid>
          </Border>

          <Border Grid.Row="2" Grid.ColumnSpan="2" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="12" Margin="0,6,0,0">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="20"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="RendererDot" Width="10" Height="10" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1"><TextBlock Text="渲染组件" FontSize="16" FontWeight="SemiBold"/><TextBlock x:Name="RendererText" Text="检测中..." Foreground="#777B83" FontSize="12"/></StackPanel>
              <TextBlock Grid.Column="2" Text="在顶部安装或更新" Foreground="#777B83" FontSize="12" VerticalAlignment="Center"/>
            </Grid>
          </Border>
        </Grid>
        <UniformGrid Columns="4" Margin="0,16,0,0">
          <Border Background="#15181C" CornerRadius="8" Padding="12" Margin="0,0,6,0"><StackPanel><TextBlock Text="GPU" Foreground="#58A6FF" FontWeight="Bold"/><TextBlock Text="自动检测" FontSize="17"/><TextBlock Text="推荐自动设备" Foreground="#777B83"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="8" Padding="12" Margin="6,0"><StackPanel><TextBlock Text="CPU" Foreground="#B56BFF" FontWeight="Bold"/><TextBlock x:Name="CpuText" Text="检测中" FontSize="17"/><TextBlock Text="多核批量处理" Foreground="#777B83"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="8" Padding="12" Margin="6,0"><StackPanel><TextBlock Text="内存" Foreground="#D69B2D" FontWeight="Bold"/><TextBlock x:Name="MemoryText" Text="-- GB" FontSize="17"/><TextBlock Text="可用于渲染" Foreground="#777B83"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="8" Padding="12" Margin="6,0,0,0"><StackPanel><TextBlock Text="推荐" Foreground="#31D69A" FontWeight="Bold"/><TextBlock x:Name="WorkerText" Text="并行 1 个任务" FontSize="17"/><TextBlock Text="低显存更稳" Foreground="#777B83"/></StackPanel></Border>
        </UniformGrid>
      </StackPanel>
    </Border>

    <Grid Margin="0,22,0,12">
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
      <StackPanel Orientation="Horizontal"><Border Width="4" Height="22" CornerRadius="3" Background="#8A8F98" Margin="0,0,10,0"/><TextBlock Text="选择模型资源目录" FontSize="22" FontWeight="Bold"/></StackPanel>
      <Button x:Name="ChooseInputButton" AutomationProperties.AutomationId="ModelRender.ChooseInputButton" Grid.Column="1" Content="选择目录" Background="#173055" Foreground="#58A6FF"/>
    </Grid>
    <Border Background="#0D0F11" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="20" MinHeight="104">
      <StackPanel HorizontalAlignment="Center"><TextBlock Text="▰" Foreground="#30343B" FontSize="34" HorizontalAlignment="Center"/><TextBlock x:Name="InputNameText" Text="TestVeh" FontSize="18" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock x:Name="InputPathText" Text="" Foreground="#666C76" FontSize="14" HorizontalAlignment="Center"/></StackPanel>
    </Border>

    <Grid Margin="0,16,0,16">
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="140"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions>
      <Button x:Name="ScanButton" AutomationProperties.AutomationId="ModelRender.ScanButton" Grid.Column="0" Height="52" Margin="0,0,8,0" FontSize="18" FontWeight="Bold" Background="#2A2D33" Content="⌕  扫描模型"/>
      <Button x:Name="RunButton" AutomationProperties.AutomationId="ModelRender.RunButton" Grid.Column="1" Height="52" Margin="8,0" FontSize="18" FontWeight="Bold" Background="#173055" Content="开始渲染"/>
      <Button x:Name="OpenOutputButton" AutomationProperties.AutomationId="ModelRender.OpenOutputButton" Grid.Column="2" Height="52" Margin="8,0,6,0" FontSize="14" Background="#0E1012" Foreground="#858B96" Content="▰  打开输出"/>
      <Button x:Name="OpenReportButton" AutomationProperties.AutomationId="ModelRender.OpenReportButton" Grid.Column="3" Height="52" Margin="6,0,0,0" FontSize="14" Background="#173055" Foreground="#58A6FF" Content="打开图片表格" IsEnabled="False"/>
    </Grid>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="20" Margin="0,0,0,16">
      <StackPanel>
        <Grid><TextBlock x:Name="RenderStatusTitle" AutomationProperties.AutomationId="ModelRender.StatusTitle" Text="等待渲染" FontSize="22" FontWeight="Bold"/><TextBlock x:Name="RenderStepText" Text="步骤 0/5: 等待任务" HorizontalAlignment="Right" Foreground="#777C84" FontSize="15"/></Grid>
        <Grid Margin="0,16,0,6"><TextBlock Text="总进度" Foreground="#868A92" FontSize="14"/><TextBlock x:Name="RenderPercent" Text="0%" HorizontalAlignment="Right" Foreground="#868A92" FontSize="14" FontWeight="Bold"/></Grid>
        <ProgressBar x:Name="RenderProgress" Height="10" Minimum="0" Maximum="100" Value="0"/>
        <UniformGrid x:Name="StepPanel" Columns="5" Margin="0,16,0,0"/>
        <TextBlock x:Name="RenderLine" AutomationProperties.AutomationId="ModelRender.ProgressText" Text="请选择资源并扫描模型。" Foreground="#7C8088" FontSize="15" Margin="0,16,0,0"/>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="20" Margin="0,0,0,20">
      <StackPanel>
        <Grid><TextBlock Text="批量渲染" FontSize="22" FontWeight="Bold"/><TextBlock x:Name="BatchCounter" Text="0/0" HorizontalAlignment="Right" Foreground="#777C84" FontSize="15"/></Grid>
        <Grid Margin="0,16,0,6"><TextBlock x:Name="BatchDoneText" Text="完成 0 / 失败 0" Foreground="#868A92" FontSize="14"/><TextBlock x:Name="BatchPercent" Text="0.0%" HorizontalAlignment="Right" Foreground="#868A92" FontSize="14" FontWeight="Bold"/></Grid>
        <ProgressBar x:Name="BatchProgress" Height="10" Minimum="0" Maximum="100" Value="0"/>
        <UniformGrid Columns="3" Margin="0,16,0,0">
          <Border Background="#15181C" CornerRadius="8" Padding="14" Margin="0,0,8,0"><StackPanel HorizontalAlignment="Center"><TextBlock Text="已用时间" Foreground="#636872" FontSize="13"/><TextBlock x:Name="ElapsedText" Text="0秒" FontSize="18" FontWeight="Bold"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="8" Padding="14" Margin="8,0"><StackPanel HorizontalAlignment="Center"><TextBlock Text="预计剩余" Foreground="#636872" FontSize="13"/><TextBlock Text="2分0秒" Foreground="#58A6FF" FontSize="18" FontWeight="Bold"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="8" Padding="14" Margin="8,0,0,0"><StackPanel HorizontalAlignment="Center"><TextBlock Text="预计完成" Foreground="#636872" FontSize="13"/><TextBlock Text="--:--:--" Foreground="#31D69A" FontSize="18" FontWeight="Bold"/></StackPanel></Border>
        </UniformGrid>
      </StackPanel>
    </Border>

    <Grid Margin="0,0,0,12"><Grid.ColumnDefinitions><ColumnDefinition Width="40"/><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions><Border Width="4" Height="22" CornerRadius="3" Background="#8A8F98"/><TextBlock Grid.Column="1" Text="模型列表" FontSize="22" FontWeight="Bold" HorizontalAlignment="Center"/><StackPanel Grid.Column="2" Orientation="Horizontal" HorizontalAlignment="Right"><Button x:Name="SelectAllButton" AutomationProperties.AutomationId="ModelRender.SelectAllButton" Content="全选" Foreground="#58A6FF" Background="#0A0B0B"/><Button x:Name="ClearButton" AutomationProperties.AutomationId="ModelRender.ClearButton" Content="取消" Foreground="#8A8F98" Background="#0A0B0B"/></StackPanel></Grid>
    <Grid>
      <Grid.ColumnDefinitions><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions>
      <ComboBox x:Name="CategoryBox" AutomationProperties.AutomationId="ModelRender.CategoryBox" Height="42" SelectedIndex="0" ToolTip="按模型分类筛选">
        <ComboBoxItem Content="全部分类" Tag="all"/><ComboBoxItem Content="载具" Tag="vehicle"/><ComboBoxItem Content="武器" Tag="weapon"/><ComboBoxItem Content="饰品" Tag="accessory"/>
      </ComboBox>
      <TextBox x:Name="SearchBox" AutomationProperties.AutomationId="ModelRender.SearchBox" Grid.Column="1" Height="42" Margin="10,0" FontSize="15" ToolTip="搜索模型名或资源路径"/>
      <ComboBox x:Name="AngleBox" AutomationProperties.AutomationId="ModelRender.AngleBox" Grid.Column="2" Height="42" SelectedIndex="0" ToolTip="选择截图角度">
        <ComboBoxItem Content="左侧" Tag="135"/><ComboBoxItem Content="正面" Tag="180"/><ComboBoxItem Content="反向正面" Tag="0"/>
      </ComboBox>
    </Grid>
    <ListView x:Name="AssetList" AutomationProperties.AutomationId="ModelRender.AssetList" MinHeight="140" MaxHeight="320" Background="#090A0A" BorderThickness="0" Margin="0,12,0,18" VirtualizingStackPanel.IsVirtualizing="True" VirtualizingStackPanel.VirtualizationMode="Recycling" ScrollViewer.CanContentScroll="True">
      <ListView.ItemTemplate>
        <DataTemplate>
          <Border Background="#151820" BorderBrush="#1E2633" BorderThickness="1" CornerRadius="8" Padding="12" Margin="0,0,0,6">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="28"/><ColumnDefinition Width="36"/><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions>
              <CheckBox IsChecked="{Binding Selected}" VerticalAlignment="Center"/>
              <TextBlock Grid.Column="1" Text="{Binding Icon}" Foreground="#69707A" FontSize="20" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="2"><TextBlock Text="{Binding Model}" FontSize="17" Foreground="#D5D8DE"/><TextBlock FontSize="13" Foreground="#5D626B"><Run Text="{Binding KindLabel}"/><Run Text=" · "/><Run Text="{Binding Source}"/></TextBlock></StackPanel>
              <TextBlock Grid.Column="3" Text="{Binding Status}" Foreground="#58A6FF" FontSize="14" VerticalAlignment="Center"/>
            </Grid>
          </Border>
        </DataTemplate>
      </ListView.ItemTemplate>
    </ListView>
    <StackPanel Orientation="Horizontal" Margin="0,0,0,12"><Border Width="4" Height="22" CornerRadius="3" Background="#8A8F98" Margin="0,0,10,0"/><TextBlock Text="渲染日志" FontSize="22" FontWeight="Bold"/></StackPanel>
    <TextBox x:Name="LogBox" AutomationProperties.AutomationId="ModelRender.LogBox" MinHeight="180" AcceptsReturn="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="13" Text="等待任务输出..."/>
  </StackPanel>
</ScrollViewer>
"@

    $root = Import-CkXaml $xaml
    $ui = Get-CkNamedControls -Root $root -Names @(
        'DependencyStatus','BlenderDot','BlenderText','BlenderDownloadButton','BlenderBrowseButton','CodeWalkerDot','CodeWalkerText','DotNetDot','DotNetText','DotNetDownloadButton',
        'SollumzDot','SollumzText','RendererDot','RendererText','CpuText','MemoryText','WorkerText',
        'InputNameText','InputPathText','ChooseInputButton','ScanButton','RunButton','OpenOutputButton','OpenReportButton',
        'RenderStatusTitle','RenderStepText','RenderPercent','RenderProgress','StepPanel','RenderLine',
        'BatchCounter','BatchDoneText','BatchPercent','BatchProgress','ElapsedText','CategoryBox','SearchBox','AngleBox','AssetList',
        'SelectAllButton','ClearButton','LogBox'
    )

    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($rows)
    $ui.AssetList.ItemsSource = $view
    New-CkStepPanel -Panel $ui.StepPanel

    $filterAction = {
        param($item)
        $categoryItem = $ui.CategoryBox.SelectedItem
        $category = if ($categoryItem -and $categoryItem.Tag) { [string]$categoryItem.Tag } else { 'all' }
        if ($category -ne 'all') {
            [string[]]$allowedKinds = switch ($category) {
                'vehicle' { @('vehicle') }
                'weapon' { @('weapon') }
                'accessory' { @('accessory', 'prop', 'drawable', 'drawable-dict') }
                default { @($category) }
            }
            if ($allowedKinds -notcontains [string]$item.Kind) { return $false }
        }

        $term = $ui.SearchBox.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($term)) { return $true }
        return (
            ([string]$item.Model).IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or
            ([string]$item.KindLabel).IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or
            ([string]$item.Source).IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
        )
    }.GetNewClosure()
    $view.Filter = [Predicate[object]]$filterAction

    function Update-Environment {
        $env = Get-CkToolboxEnvironment -Context $Context

        $ui.BlenderText.Text = $env.Blender.Label
        $ui.BlenderText.ToolTip = if ($env.Blender.Path) { $env.Blender.Path } else { '点击“选择”并指定 blender.exe' }
        $ui.BlenderBrowseButton.ToolTip = '选择 Blender 安装目录中的 blender.exe'
        Set-CkStatusDot $ui.BlenderDot $env.Blender.Ok
        $ui.CodeWalkerText.Text = $env.CodeWalker.Label
        Set-CkStatusDot $ui.CodeWalkerDot $env.CodeWalker.Ok
        $ui.DotNetText.Text = $env.DotNet.Label
        Set-CkStatusDot $ui.DotNetDot $env.DotNet.Ok
        $ui.SollumzText.Text = $env.Sollumz.Label
        Set-CkStatusDot $ui.SollumzDot $env.Sollumz.Ok
        $ui.RendererText.Text = $env.Renderer.Label
        Set-CkStatusDot $ui.RendererDot $env.Renderer.Ok
        $ui.DependencyStatus.Text = if ($env.AllOk) { '全部就绪' } else { '请处理缺失项' }
        $ui.DependencyStatus.Foreground = if ($env.AllOk) { '#31D69A' } else { '#F4B860' }
        $ui.CpuText.Text = $env.CpuName
        $ui.MemoryText.Text = if ($env.MemoryGb) { "$($env.MemoryGb) GB" } else { '-- GB' }
        $ui.WorkerText.Text = "并行 $($env.RecommendedWorkers) 个任务"
    }

    function Refresh-InputText {
        $ui.InputNameText.Text = Split-Path -Leaf $state.InputPath
        $ui.InputPathText.Text = $state.InputPath
    }

    function Scan-AssetsForPage {
        try {
            $ui.RenderStatusTitle.Text = '正在扫描'
            $ui.RenderLine.Text = '正在扫描模型资源...'
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $found = Get-CkRenderableAssets -Path $state.InputPath
            $rows.Clear()
            foreach ($row in $found) { [void]$rows.Add($row) }
            $stopwatch.Stop()
            $ui.RenderStatusTitle.Text = '扫描完成'
            $ui.RenderLine.Text = "已发现 $($rows.Count) 个可处理模型，用时 $([Math]::Round($stopwatch.Elapsed.TotalSeconds, 2)) 秒。"
        } catch {
            $ui.RenderStatusTitle.Text = '扫描失败'
            $ui.RenderLine.Text = $_.Exception.Message
        }
    }

    function Update-ProgressFromLine {
        param([string]$Line)
        if ($Line -match '^Assets:\s*(\d+)') {
            $state.Total = [int]$Matches[1]
            $ui.RenderProgress.Value = [Math]::Max($ui.RenderProgress.Value, 12)
            Set-CkStepState -Panel $ui.StepPanel -Step 2 -Label '导入模型' -LabelControl $ui.RenderStepText
        } elseif ($Line -match '^\[archive\]|^\[rpf\]') {
            $ui.RenderProgress.Value = [Math]::Max($ui.RenderProgress.Value, 8)
            Set-CkStepState -Panel $ui.StepPanel -Step 1 -Label '导出模型' -LabelControl $ui.RenderStepText
        } elseif ($Line -match '^\[textures\]' -and $Line -notmatch 'report=') {
            $ui.RenderProgress.Value = [Math]::Max($ui.RenderProgress.Value, 46)
            Set-CkStepState -Panel $ui.StepPanel -Step 3 -Label '转换纹理' -LabelControl $ui.RenderStepText
        } elseif ($Line -match '^\[textures\].*report=') {
            $ui.RenderProgress.Value = [Math]::Max($ui.RenderProgress.Value, 68)
            Set-CkStepState -Panel $ui.StepPanel -Step 4 -Label '绑定材质' -LabelControl $ui.RenderStepText
        } elseif ($Line -match '^\[ok\]') {
            $state.Done++
            Set-CkStepState -Panel $ui.StepPanel -Step 5 -Label 'Blender渲染' -LabelControl $ui.RenderStepText
        } elseif ($Line -match '^\[fail\]') {
            $state.Failed++
            Set-CkStepState -Panel $ui.StepPanel -Step 5 -Label 'Blender渲染' -LabelControl $ui.RenderStepText
        }

        $finished = $state.Done + $state.Failed
        $total = [Math]::Max(1, $state.Total)
        if ($finished -gt 0) {
            $ui.RenderProgress.Value = [Math]::Max($ui.RenderProgress.Value, [Math]::Min(92, 18 + ($finished / $total * 72)))
        }
        $ui.RenderPercent.Text = '{0}%' -f [int]$ui.RenderProgress.Value
        $ui.BatchCounter.Text = "$([Math]::Min($finished, $total))/$total"
        $ui.BatchDoneText.Text = "完成 $($state.Done) / 失败 $($state.Failed)"
        $ui.BatchProgress.Value = [Math]::Min(100, $finished / $total * 100)
        $ui.BatchPercent.Text = '{0:0.0}%' -f $ui.BatchProgress.Value
        if ($state.StartedAt) {
            $elapsed = (Get-Date) - $state.StartedAt
            $ui.ElapsedText.Text = if ($elapsed.TotalSeconds -ge 60) { '{0}分{1}秒' -f [int]$elapsed.TotalMinutes, $elapsed.Seconds } else { '{0}秒' -f [int]$elapsed.TotalSeconds }
        }
        $progressText = $null
        if ($Line -match '^Blender:') {
            $progressText = '已检测到 Blender，正在准备渲染。'
        } elseif ($Line -match '^Input:') {
            $progressText = '正在读取模型资源目录。'
        } elseif ($Line -match '^Output:') {
            $progressText = '输出目录已准备完成。'
        } elseif ($Line -match '^Assets:\s*(\d+)') {
            $progressText = "发现 $($Matches[1]) 个待处理模型。"
        } elseif ($Line -match '^Requested asset types:|^Scanned asset groups:') {
            $progressText = '模型类型筛选完成。'
        } elseif ($Line -match '^Model tone:') {
            $progressText = '正在准备模型材质。'
        } elseif ($Line -match '^Workers:\s*(\d+)') {
            $progressText = "已启动 $($Matches[1]) 个渲染任务。"
        } elseif ($Line -match '^Shared YTD:') {
            $progressText = '正在加载共享贴图。'
        } elseif ($Line -match '^Cutout:') {
            $progressText = '正在配置透明背景截图。'
        } elseif ($Line -match '^\[archive\]') {
            $progressText = '正在解压模型资源包。'
        } elseif ($Line -match '^\[rpf\]') {
            $progressText = '正在解析 RPF 资源。'
        } elseif ($Line -match '^\[textures\].*report=') {
            $progressText = '贴图与材质处理完成，详情已写入日志。'
        } elseif ($Line -match '^\[textures\]') {
            $progressText = '正在转换贴图并绑定材质。'
        } elseif ($Line -match '^\[ok\]\s+(\S+)') {
            $progressText = "模型 $($Matches[1]) 渲染完成。"
        } elseif ($Line -match '^\[fail\]\s+(\S+)') {
            $progressText = "模型 $($Matches[1]) 渲染失败。"
        } elseif ($Line -match '^Done\.\s+OK=(\d+)\s+FAIL=(\d+)') {
            $progressText = "处理完成：成功 $($Matches[1])，失败 $($Matches[2])。"
        }
        if ($progressText) {
            $ui.RenderLine.Text = $progressText
        }
    }

    $refreshInputAction = (Get-Command Refresh-InputText).ScriptBlock.GetNewClosure()
    $updateEnvironmentAction = (Get-Command Update-Environment).ScriptBlock.GetNewClosure()
    $scanAssetsAction = (Get-Command Scan-AssetsForPage).ScriptBlock.GetNewClosure()
    $updateProgressAction = (Get-Command Update-ProgressFromLine).ScriptBlock.GetNewClosure()

    $showPageError = {
        param([string]$message)
        $ui.RenderStatusTitle.Text = '操作失败'
        $ui.RenderLine.Text = $message
        Add-CkLogLine -TextBox $ui.LogBox -Line "[工具箱] $message"
        [System.Windows.MessageBox]::Show(
            $message,
            'CK免费工具箱 - 操作失败',
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }.GetNewClosure()

    $chooseInputAction = {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = '选择包含 FiveM / GTA 模型资源的目录'
        $dialog.SelectedPath = $state.InputPath
        $dialog.ShowNewFolderButton = $false
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $state.InputPath = $dialog.SelectedPath
                & $refreshInputAction
                $ui.RenderStatusTitle.Text = '目录已更新'
                $ui.RenderLine.Text = '点击“扫描模型”读取新目录。'
            }
        } finally {
            $dialog.Dispose()
        }
    }.GetNewClosure()

    $scanButtonAction = {
        $content = $ui.ScanButton.Content
        $ui.ScanButton.IsEnabled = $false
        $ui.ScanButton.Content = '正在扫描...'
        try {
            & $scanAssetsAction
            $view.Refresh()
            $ui.BatchCounter.Text = "0/$(@($view).Count)"
        } finally {
            $ui.ScanButton.IsEnabled = $true
            $ui.ScanButton.Content = $content
        }
    }.GetNewClosure()

    $selectAllAction = {
        foreach ($row in $view) { $row.Selected = $true }
        $ui.AssetList.Items.Refresh()
    }.GetNewClosure()

    $clearAction = {
        foreach ($row in $view) { $row.Selected = $false }
        $ui.AssetList.Items.Refresh()
    }.GetNewClosure()

    $searchAction = {
        $view.Refresh()
        $ui.BatchCounter.Text = "0/$(@($view).Count)"
    }.GetNewClosure()

    $openOutputAction = {
        if ([string]::IsNullOrWhiteSpace($state.OutputPath)) { throw '输出目录不能为空。' }
        if (-not (Test-Path -LiteralPath $state.OutputPath)) {
            New-Item -ItemType Directory -Force -Path $state.OutputPath | Out-Null
        }
        Start-Process -FilePath explorer.exe -ArgumentList @($state.OutputPath)
    }.GetNewClosure()

    $openReportAction = {
        $path = [string]$state.ReportPath
        if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw '本次模型渲染报告不存在，请先完成一次渲染。'
        }
        $extension = [IO.Path]::GetExtension($path).ToLowerInvariant()
        if (@('.html', '.htm') -contains $extension) {
            Start-Process -FilePath $path -ErrorAction Stop
        } else {
            Start-Process -FilePath notepad.exe -ArgumentList @("`"$path`"") -ErrorAction Stop
        }
    }.GetNewClosure()

    $renderAction = {
        if ($state.Process -and -not $state.Process.Process.HasExited) {
            throw '已有渲染任务正在运行。'
        }
        if (-not (Test-Path -LiteralPath $Context.Paths.RenderScript -PathType Leaf)) {
            throw "渲染脚本不存在: $($Context.Paths.RenderScript)"
        }
        if (-not (Test-Path -LiteralPath $state.InputPath)) {
            throw "资源路径不存在: $($state.InputPath)"
        }

        $selected = @($view | Where-Object { $_.Selected })
        if (-not $selected.Count) {
            [System.Windows.MessageBox]::Show('请先扫描并选择模型。', 'CK免费工具箱') | Out-Null
            return
        }

        $env = Get-CkToolboxEnvironment -Context $Context

        if (-not $env.Blender.Ok) { throw '未检测到 Blender，请安装后选择 Blender 目录。' }
        if (-not $env.DotNet.Ok) { throw '未检测到系统 .NET Framework 4.8，请点击官网按钮安装。' }
        if (-not $env.CodeWalker.Ok) { throw '模型组件缺少内置转换工具，请点击顶部安装组件按钮重新安装。' }
        if (-not $env.Sollumz.Ok) { throw '模型组件缺少内置 Sollumz，请点击顶部安装组件按钮重新安装。' }
        $settings = Get-CkDependencySettings
        $pythonExe = Get-CkPythonExe -RuntimeRoot $Context.Paths.RuntimeRoot -BlenderExe $env.Blender.Path -ConfiguredPath ([string]$settings.PythonPath) -PreferBlender
        $categoryItem = $ui.CategoryBox.SelectedItem
        $category = if ($categoryItem -and $categoryItem.Tag) { [string]$categoryItem.Tag } else { 'all' }
        $assetType = switch ($category) {
            'accessory' { 'drawable,drawable-dict' }
            default { $category }
        }
        $angleItem = $ui.AngleBox.SelectedItem
        $yaw = if ($angleItem -and $angleItem.Tag) { [string]$angleItem.Tag } else { '135' }
        $args = @(
            '-u',
            $Context.Paths.RenderScript,
            $state.InputPath,

            '--blender', $env.Blender.Path,
            '--out', $state.OutputPath,
            '--asset-types', $assetType,
            '--yaw', $yaw,
            '--ytd-mode', 'match',
            '--workers', $env.RecommendedWorkers,
            '--force',
            '--cutout',
            '--sollumz', $env.Sollumz.Path,
            '--ytd-tool', $env.CodeWalker.YtdTool,
            '--rpf-tool', $env.CodeWalker.RpfTool
        )
        foreach ($row in $selected) {
            if ($row.Kind -ne 'archive') { $args += @('--model', $row.Model) }
        }

        $selectedKeys = @{}
        foreach ($row in $selected) {
            $selectedKeys["$($row.Kind)|$($row.Model)|$($row.Source)"] = $true
        }
        foreach ($row in $rows) {
            $key = "$($row.Kind)|$($row.Model)|$($row.Source)"
            $row.Status = if ($selectedKeys.ContainsKey($key)) { '渲染中' } else { '跳过' }
        }
        $ui.AssetList.Items.Refresh()
        $ui.LogBox.Text = ''
        $ui.RunButton.IsEnabled = $false
        $ui.RunButton.Content = '正在渲染...'
        $ui.RenderStatusTitle.Text = '正在渲染'
        $ui.RenderProgress.Value = 2
        $ui.RenderPercent.Text = '2%'
        $ui.BatchProgress.Value = 0
        $state.Total = $selected.Count
        $state.Done = 0
        $state.Failed = 0
        $state.StartedAt = Get-Date
        $state.ReportPath = ''
        $state.ReportHistoryPath = ''
        $ui.OpenReportButton.IsEnabled = $false
        Set-CkStepState -Panel $ui.StepPanel -Step 1 -Label '导出模型' -LabelControl $ui.RenderStepText

        $callbackState = $state
        $callbackUi = $ui
        $callbackRows = $rows
        $callbackSelectedKeys = $selectedKeys
        $callbackProgress = $updateProgressAction
        $callbackOutputPath = $state.OutputPath
        $onOutput = {
            param($line)
            Add-CkLogLine -TextBox $callbackUi.LogBox -Line $line
            if ($line -match '^\[report\]\s+history-html=(.+)$') {
                $callbackState.ReportHistoryPath = $Matches[1].Trim()
                $callbackState.ReportPath = $callbackState.ReportHistoryPath
            } elseif (-not $callbackState.ReportHistoryPath -and $line -match '^\[report\]\s+html=(.+)$') {
                $callbackState.ReportPath = $Matches[1].Trim()
            } elseif (-not $callbackState.ReportHistoryPath -and $line -match '^\[report\]\s+history=(.+)$') {
                $callbackState.ReportHistoryPath = $Matches[1].Trim()
                $callbackState.ReportPath = $callbackState.ReportHistoryPath
            } elseif (-not $callbackState.ReportPath -and $line -match '^\[report\]\s+markdown=(.+)$') {
                $callbackState.ReportPath = $Matches[1].Trim()
            }
            & $callbackProgress $line
        }.GetNewClosure()
        $onProcessError = {
            param($message)
            Add-CkLogLine -TextBox $callbackUi.LogBox -Line "[工具箱回调错误] $message"
            $callbackUi.RenderLine.Text = $message
        }.GetNewClosure()
        $onExit = {
            param($exitCode)
            $callbackState.Process = $null
            $callbackUi.RenderProgress.Value = if ($exitCode -eq 0) { 100 } else { [Math]::Max($callbackUi.RenderProgress.Value, 95) }
            $callbackUi.RenderPercent.Text = '{0}%' -f [int]$callbackUi.RenderProgress.Value
            $callbackUi.RenderStatusTitle.Text = if ($exitCode -eq 0) { '渲染完成' } else { '渲染失败' }
            $callbackUi.RunButton.IsEnabled = $true
            $callbackUi.RunButton.Content = '开始渲染'
            foreach ($row in $callbackRows) {
                $key = "$($row.Kind)|$($row.Model)|$($row.Source)"
                if ($callbackSelectedKeys.ContainsKey($key)) { $row.Status = if ($exitCode -eq 0) { '完成' } else { '失败' } }
            }
            $callbackUi.AssetList.Items.Refresh()
            $reportPath = [string]$callbackState.ReportPath
            if (-not $reportPath -or -not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
                foreach ($candidateName in @('_render_gallery.html', '_render_report.md', '_render_report.json')) {
                    $candidate = Join-Path $callbackOutputPath $candidateName
                    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                        $candidateFile = Get-Item -LiteralPath $candidate
                        if ($candidateFile.LastWriteTimeUtc -ge $callbackState.StartedAt.ToUniversalTime()) {
                            $reportPath = $candidateFile.FullName
                            break
                        }
                    }
                }
            }
            if ($reportPath -and (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
                $callbackState.ReportPath = [IO.Path]::GetFullPath($reportPath)
                $callbackUi.OpenReportButton.IsEnabled = $true
                Add-CkLogLine -TextBox $callbackUi.LogBox -Line "本次报告: $($callbackState.ReportPath)"
            } else {
                $callbackState.ReportPath = ''
                $callbackUi.OpenReportButton.IsEnabled = $false
            }
            Add-CkLogLine -TextBox $callbackUi.LogBox -Line "退出码: $exitCode"
        }.GetNewClosure()

        try {
            $state.Process = Start-CkLoggedProcess -FileName $pythonExe -Arguments $args -WorkingDirectory $Context.Paths.RendererDir -Dispatcher $Context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onProcessError
        } catch {
            $ui.RunButton.IsEnabled = $true
            $ui.RunButton.Content = '开始渲染'
            $ui.RenderStatusTitle.Text = '启动失败'
            throw
        }
    }.GetNewClosure()

    function Select-CkBlenderExecutable {
        $settings = Get-CkDependencySettings
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Title = '选择 Blender 主程序 blender.exe'
        $dialog.Filter = 'Blender 主程序 (blender.exe)|blender.exe|可执行文件 (*.exe)|*.exe'
        $dialog.CheckFileExists = $true
        $dialog.Multiselect = $false
        $dialog.RestoreDirectory = $true

        $savedPath = [string]$settings.BlenderPath
        if ($savedPath -and (Test-Path -LiteralPath $savedPath -PathType Leaf)) {
            $dialog.InitialDirectory = Split-Path -Parent $savedPath
            $dialog.FileName = $savedPath
        } elseif ($savedPath -and (Test-Path -LiteralPath $savedPath -PathType Container)) {
            $dialog.InitialDirectory = $savedPath
        } else {
            $detected = Get-CkToolboxEnvironment -Context $Context
            if ($detected.Blender.Ok) {
                $dialog.InitialDirectory = Split-Path -Parent $detected.Blender.Path
                $dialog.FileName = $detected.Blender.Path
            }
        }

        $owner = [System.Windows.Window]::GetWindow($root)
        $accepted = if ($owner) { $dialog.ShowDialog($owner) } else { $dialog.ShowDialog() }
        if ($accepted -ne $true) { return }
        $selected = [IO.Path]::GetFullPath($dialog.FileName)
        if ([IO.Path]::GetFileName($selected) -ine 'blender.exe') {
            throw '请选择 Blender 安装目录中的 blender.exe。'
        }

        $saved = Set-CkDependencyPath -Dependency Blender -Path $selected
        & $updateEnvironmentAction
        $environment = Get-CkToolboxEnvironment -Context $Context
        if (-not [string]::Equals($environment.Blender.Path, $saved, [StringComparison]::OrdinalIgnoreCase)) {
            throw '所选 blender.exe 无法识别，请确认 Blender 已完整安装。'
        }
        if (-not $environment.Blender.Ok) {
            throw [string]$environment.Blender.Label
        }

        $message = "已识别 $($environment.Blender.Label)`n`n$($environment.Blender.Path)"
        if ($owner) {
            [System.Windows.MessageBox]::Show($owner, $message, 'Blender 设置完成', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        } else {
            [System.Windows.MessageBox]::Show($message, 'Blender 设置完成', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        }
    }
    $selectBlenderExecutableAction = (Get-Command Select-CkBlenderExecutable).ScriptBlock.GetNewClosure()
    $openBlenderDownloadAction = { Start-Process -FilePath 'https://www.blender.org/download/' }.GetNewClosure()
    $openDotNetDownloadAction = { Start-Process -FilePath 'https://dotnet.microsoft.com/download/dotnet-framework/net48' }.GetNewClosure()
    $browseBlenderAction = { & $selectBlenderExecutableAction }.GetNewClosure()

    Register-CkButtonAction -Button $ui.BlenderDownloadButton -Action $openBlenderDownloadAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.BlenderBrowseButton -Action $browseBlenderAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.DotNetDownloadButton -Action $openDotNetDownloadAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseInputButton -Action $chooseInputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ScanButton -Action $scanButtonAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.SelectAllButton -Action $selectAllAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ClearButton -Action $clearAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenOutputButton -Action $openOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenReportButton -Action $openReportAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.RunButton -Action $renderAction -OnError $showPageError
    Register-CkTextChangedAction -TextBox $ui.SearchBox -Action $searchAction
    $ui.CategoryBox.add_SelectionChanged($searchAction)

    & $refreshInputAction
    & $updateEnvironmentAction
    & $scanAssetsAction
    $view.Refresh()
    $ui.BatchCounter.Text = "0/$(@($view).Count)"

    return [pscustomobject]@{
        Id = 'model-render'
        Title = '模型自动截图'
        Icon = '▧'
        Root = $root
        Activate = $updateEnvironmentAction
    }
}
