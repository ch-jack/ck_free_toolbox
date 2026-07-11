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
    }

    $xaml = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
              xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
              VerticalScrollBarVisibility="Auto" Padding="26,14,30,36">
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
        <UniformGrid Columns="2" Rows="3">
<Button x:Name="BlenderDependencyButton" AutomationProperties.AutomationId="ModelRender.BlenderDependencyButton" Background="#16181B" BorderBrush="#242833" BorderThickness="1" Padding="14" Margin="0,0,8,8" HorizontalContentAlignment="Stretch" VerticalContentAlignment="Stretch">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="22"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="BlenderDot" Width="12" Height="12" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1"><TextBlock Text="Blender" FontSize="20" FontWeight="SemiBold"/><TextBlock x:Name="BlenderText" Text="检测中..." Foreground="#777B83" FontSize="14"/></StackPanel>
              <TextBlock x:Name="BlenderActionText" Grid.Column="2" VerticalAlignment="Center" Foreground="#58A6FF" FontSize="13" FontWeight="SemiBold"/>
            </Grid>
          </Button>
          <Border Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="14" Margin="8,0,0,8">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="22"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="CodeWalkerDot" Width="12" Height="12" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1"><TextBlock Text="CodeWalker" FontSize="20" FontWeight="SemiBold"/><TextBlock x:Name="CodeWalkerText" Text="检测中..." Foreground="#777B83" FontSize="14"/></StackPanel>
            </Grid>
          </Border>
          <Border Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="14" Margin="0,8,8,8">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="22"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="DotNetDot" Width="12" Height="12" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1"><TextBlock Text=".NET 4.8" FontSize="20" FontWeight="SemiBold"/><TextBlock x:Name="DotNetText" Text="检测中..." Foreground="#777B83" FontSize="14"/></StackPanel>
            </Grid>
          </Border>
          <Border Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="14" Margin="8,8,0,8">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="22"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="SollumzDot" Width="12" Height="12" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1"><TextBlock Text="Sollumz 插件" FontSize="20" FontWeight="SemiBold"/><TextBlock x:Name="SollumzText" Text="检测中..." Foreground="#777B83" FontSize="14"/></StackPanel>
            </Grid>
          </Border>
          <Border Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="14" Margin="0,8,8,0">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="22"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="RendererDot" Width="12" Height="12" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1"><TextBlock Text="渲染脚本" FontSize="20" FontWeight="SemiBold"/><TextBlock x:Name="RendererText" Text="检测中..." Foreground="#777B83" FontSize="14"/></StackPanel>
            </Grid>
          </Border>
        </UniformGrid>
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
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions>
      <Button x:Name="ScanButton" AutomationProperties.AutomationId="ModelRender.ScanButton" Grid.Column="0" Height="52" Margin="0,0,8,0" FontSize="18" FontWeight="Bold" Background="#2A2D33" Content="⌕  扫描模型"/>
      <Button x:Name="RunButton" AutomationProperties.AutomationId="ModelRender.RunButton" Grid.Column="1" Height="52" Margin="8,0,8,0" FontSize="18" FontWeight="Bold" Background="#173055" Content="开始渲染"/>
      <Button x:Name="OpenOutputButton" AutomationProperties.AutomationId="ModelRender.OpenOutputButton" Grid.Column="2" Height="52" Margin="8,0,0,0" FontSize="15" Background="#0E1012" Foreground="#858B96" Content="▰  打开输出"/>
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
    <TextBox x:Name="SearchBox" AutomationProperties.AutomationId="ModelRender.SearchBox" Height="42" FontSize="15" ToolTip="搜索模型名或资源路径"/>
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
        'DependencyStatus','BlenderDependencyButton','BlenderDot','BlenderText','BlenderActionText','CodeWalkerDot','CodeWalkerText','DotNetDot','DotNetText',
        'SollumzDot','SollumzText','RendererDot','RendererText','CpuText','MemoryText','WorkerText',
        'InputNameText','InputPathText','ChooseInputButton','ScanButton','RunButton','OpenOutputButton',
        'RenderStatusTitle','RenderStepText','RenderPercent','RenderProgress','StepPanel','RenderLine',
        'BatchCounter','BatchDoneText','BatchPercent','BatchProgress','ElapsedText','SearchBox','AssetList',
        'SelectAllButton','ClearButton','LogBox'
    )

    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($rows)
    $ui.AssetList.ItemsSource = $view
    New-CkStepPanel -Panel $ui.StepPanel

    $filterAction = {
        param($item)
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

        $ui.BlenderText.Text = $env.Blender.Label; Set-CkStatusDot $ui.BlenderDot $env.Blender.Ok
        $ui.BlenderActionText.Text = if ($env.Blender.Ok) { '已就绪' } else { '官网下载' }
        $ui.BlenderActionText.Foreground = if ($env.Blender.Ok) { '#31D69A' } else { '#58A6FF' }
        $ui.BlenderDependencyButton.Cursor = if ($env.Blender.Ok) { [System.Windows.Input.Cursors]::Arrow } else { [System.Windows.Input.Cursors]::Hand }
        $ui.BlenderDependencyButton.ToolTip = if ($env.Blender.Ok) { '已检测到 Blender' } else { '点击打开 Blender 官方下载页' }
        $ui.CodeWalkerText.Text = $env.CodeWalker.Label; Set-CkStatusDot $ui.CodeWalkerDot $env.CodeWalker.Ok
        $ui.DotNetText.Text = $env.DotNet.Label; Set-CkStatusDot $ui.DotNetDot $env.DotNet.Ok
        $ui.SollumzText.Text = $env.Sollumz.Label; Set-CkStatusDot $ui.SollumzDot $env.Sollumz.Ok
        $ui.RendererText.Text = $env.Renderer.Label; Set-CkStatusDot $ui.RendererDot $env.Renderer.Ok
        $ui.DependencyStatus.Text = if ($env.AllOk) { '通过 ✓' } else { '需检查' }
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
            $ui.BatchCounter.Text = "0/$($rows.Count)"
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

    $searchAction = { $view.Refresh() }.GetNewClosure()

    $openOutputAction = {
        if ([string]::IsNullOrWhiteSpace($state.OutputPath)) { throw '输出目录不能为空。' }
        if (-not (Test-Path -LiteralPath $state.OutputPath)) {
            New-Item -ItemType Directory -Force -Path $state.OutputPath | Out-Null
        }
        Start-Process -FilePath explorer.exe -ArgumentList @($state.OutputPath)
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

        $selected = @($rows | Where-Object { $_.Selected })
        if (-not $selected.Count) {
            [System.Windows.MessageBox]::Show('请先扫描并选择模型。', 'CK免费工具箱') | Out-Null
            return
        }

        $env = Get-CkToolboxEnvironment -Context $Context

        if (-not $env.Blender.Ok) { throw '未检测到 Blender。请点击上方 Blender 环境依赖前往官网下载。' }
        $pythonExe = Get-CkPythonExe -RuntimeRoot $Context.Paths.RuntimeRoot -BlenderExe $env.Blender.Path
        $args = @(
            '-u',
            $Context.Paths.RenderScript,
            $state.InputPath,

            '--blender', $env.Blender.Path,
            '--out', $state.OutputPath,
            '--asset-types', 'all',
            '--workers', $env.RecommendedWorkers,
            '--force',
            '--cutout'
        )
        foreach ($row in $selected) {
            if ($row.Kind -ne 'archive') { $args += @('--model', $row.Model) }
        }

        foreach ($row in $rows) {
            $row.Status = if ($row.Selected) { '渲染中' } else { '跳过' }
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
        Set-CkStepState -Panel $ui.StepPanel -Step 1 -Label '导出模型' -LabelControl $ui.RenderStepText

        $callbackState = $state
        $callbackUi = $ui
        $callbackRows = $rows
        $callbackProgress = $updateProgressAction
        $onOutput = {
            param($line)
            Add-CkLogLine -TextBox $callbackUi.LogBox -Line $line
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
                if ($row.Selected) { $row.Status = if ($exitCode -eq 0) { '完成' } else { '失败' } }
            }
            $callbackUi.AssetList.Items.Refresh()
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

    $openBlenderDownloadAction = {
        $currentEnvironment = Get-CkToolboxEnvironment -Context $Context
        if (-not $currentEnvironment.Blender.Ok) {
            Start-Process -FilePath 'https://www.blender.org/download/'
        }
    }.GetNewClosure()

    Register-CkButtonAction -Button $ui.BlenderDependencyButton -Action $openBlenderDownloadAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseInputButton -Action $chooseInputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ScanButton -Action $scanButtonAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.SelectAllButton -Action $selectAllAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ClearButton -Action $clearAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenOutputButton -Action $openOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.RunButton -Action $renderAction -OnError $showPageError
    Register-CkTextChangedAction -TextBox $ui.SearchBox -Action $searchAction

    & $refreshInputAction
    & $updateEnvironmentAction
    & $scanAssetsAction
    $view.Refresh()

    return [pscustomobject]@{
        Id = 'model-render'
        Title = '模型自动截图'
        Icon = '▧'
        Root = $root
        Activate = { }
    }
}
