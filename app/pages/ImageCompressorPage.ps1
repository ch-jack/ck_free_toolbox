function New-CkImageCompressorPage {
    param([Parameter(Mandatory)]$Context)

    $rows = New-Object 'System.Collections.ObjectModel.ObservableCollection[object]'
    $state = [pscustomobject]@{
        Process = $null
        CancelRequested = $false
        ReportCsv = ''
        ReportJson = ''
        OutputPath = ''
    }

    $xaml = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
              xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
              VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"
              Padding="22,16,28,32">
  <ScrollViewer.Resources>
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#C4CBD5"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="VerticalAlignment" Value="Center"/>
    </Style>
  </ScrollViewer.Resources>
  <StackPanel>
    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12">
          <StackPanel Orientation="Horizontal">
            <Border Width="4" Height="22" CornerRadius="3" Background="#4CB7A5" Margin="0,0,10,0"/>
            <StackPanel>
              <TextBlock Text="图片批量压缩" FontSize="21" FontWeight="Bold"/>
              <TextBlock Text="FFmpeg · JPG / PNG / GIF / WebP · 递归目录 · 动画保留 · CSV/JSON 报告" Foreground="#AAB2BE" FontSize="12" Margin="0,4,0,0"/>
            </StackPanel>
          </StackPanel>
          <TextBlock x:Name="EnvironmentStatus" Text="检测中" HorizontalAlignment="Right" VerticalAlignment="Center" Foreground="#F4B860" FontSize="14" FontWeight="SemiBold"/>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Border Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="10" Margin="0,0,6,0">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/><ColumnDefinition Width="56"/></Grid.ColumnDefinitions><Ellipse x:Name="PythonDot" Width="9" Height="9" Fill="#F4B860" VerticalAlignment="Center"/><StackPanel Grid.Column="1"><TextBlock Text="Python 3.7+" FontWeight="SemiBold"/><TextBlock x:Name="PythonText" Text="检测中" Foreground="#AAB2BE" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel><Button x:Name="PythonBrowseButton" Grid.Column="2" Content="选择" Height="28"/></Grid>
          </Border>
          <Border Grid.Column="1" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="10" Margin="6,0">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/><ColumnDefinition Width="56"/></Grid.ColumnDefinitions><Ellipse x:Name="FFmpegDot" Width="9" Height="9" Fill="#F4B860" VerticalAlignment="Center"/><StackPanel Grid.Column="1"><TextBlock Text="FFmpeg + ffprobe" FontWeight="SemiBold"/><TextBlock x:Name="FFmpegText" Text="检测中" Foreground="#AAB2BE" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel><Button x:Name="FFmpegBrowseButton" Grid.Column="2" Content="选择" Height="28"/></Grid>
          </Border>
          <Border Grid.Column="2" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="10" Margin="6,0,0,0">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Ellipse x:Name="ComponentDot" Width="9" Height="9" Fill="#F4B860" VerticalAlignment="Center"/><StackPanel Grid.Column="1"><TextBlock Text="压缩组件" FontWeight="SemiBold"/><TextBlock x:Name="ComponentText" Text="检测中" Foreground="#AAB2BE" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel></Grid>
          </Border>
        </Grid>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,9,0,0"><Button x:Name="PythonDownloadButton" Content="Python 官网" Height="27" Margin="0,0,7,0" Foreground="#72B7F2"/><Button x:Name="FFmpegDownloadButton" Content="FFmpeg 官网" Height="27" Foreground="#72B7F2"/></StackPanel>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="输入与输出" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid Margin="0,0,0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><TextBox x:Name="InputBox" Height="38"/><Button x:Name="ChooseInputFolderButton" Grid.Column="1" Content="选择目录" Height="38" Margin="8,0,0,0"/><Button x:Name="ChooseInputFileButton" Grid.Column="2" Content="选择文件" Height="38" Margin="8,0,0,0"/></Grid>
        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><TextBox x:Name="OutputBox" Height="38"/><Button x:Name="ChooseOutputButton" Grid.Column="1" Content="选择输出" Height="38" Margin="8,0,0,0"/><Button x:Name="OpenOutputButton" Grid.Column="2" Content="打开输出" Height="38" Margin="8,0,0,0" IsEnabled="False"/></Grid>
        <Grid Margin="0,10,0,0"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><CheckBox x:Name="RecursiveCheck" Content="递归子目录" IsChecked="True" Margin="0,0,18,0"/><CheckBox x:Name="InPlaceCheck" Grid.Column="1" Content="原地压缩（自动备份）" Margin="0,0,18,0" Foreground="#F4B860"/><CheckBox x:Name="OverwriteCheck" Grid.Column="2" Content="覆盖已有输出"/><TextBlock Grid.Column="3" Text="默认写入独立目录，不修改源文件" HorizontalAlignment="Right" Foreground="#6E7580" FontSize="12"/></Grid>
        <Grid x:Name="BackupGrid" Margin="0,10,0,0" IsEnabled="False"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><TextBox x:Name="BackupBox" Height="36" ToolTip="留空时在输入路径外自动创建带时间戳的备份"/><Button x:Name="ChooseBackupButton" Grid.Column="1" Content="备份目录" Height="36" Margin="8,0,0,0"/></Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="格式与通用参数" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid Margin="0,0,0,12"><Grid.ColumnDefinitions><ColumnDefinition Width="130"/><ColumnDefinition Width="130"/><ColumnDefinition Width="130"/><ColumnDefinition Width="130"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><CheckBox x:Name="JpgCheck" Content="JPG / JPEG" IsChecked="True"/><CheckBox x:Name="PngCheck" Grid.Column="1" Content="PNG" IsChecked="True"/><CheckBox x:Name="GifCheck" Grid.Column="2" Content="GIF" IsChecked="True"/><CheckBox x:Name="WebpCheck" Grid.Column="3" Content="WebP" IsChecked="True"/><TextBlock Grid.Column="4" Text="动态 GIF/WebP 会校验动画没有变成单帧" Foreground="#6E7580" FontSize="12" VerticalAlignment="Center"/></Grid>
        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <StackPanel Margin="0,0,6,0"><TextBlock Text="通用画质 1-100" Foreground="#AAB2BE" FontSize="12"/><TextBox x:Name="QualityBox" Text="80" Height="36" Margin="0,5,0,0"/></StackPanel>
          <StackPanel Grid.Column="1" Margin="6,0"><TextBlock Text="JPG 画质" Foreground="#AAB2BE" FontSize="12"/><TextBox x:Name="JpgQualityBox" Text="82" Height="36" Margin="0,5,0,0"/></StackPanel>
          <StackPanel Grid.Column="2" Margin="6,0"><TextBlock Text="WebP 画质" Foreground="#AAB2BE" FontSize="12"/><TextBox x:Name="WebpQualityBox" Text="80" Height="36" Margin="0,5,0,0"/></StackPanel>
          <StackPanel Grid.Column="3" Margin="6,0"><TextBlock Text="最大宽度（0不限）" Foreground="#AAB2BE" FontSize="12"/><TextBox x:Name="MaxWidthBox" Text="0" Height="36" Margin="0,5,0,0"/></StackPanel>
          <StackPanel Grid.Column="4" Margin="6,0"><TextBlock Text="最大高度（0不限）" Foreground="#AAB2BE" FontSize="12"/><TextBox x:Name="MaxHeightBox" Text="0" Height="36" Margin="0,5,0,0"/></StackPanel>
          <StackPanel Grid.Column="5" Margin="6,0,0,0"><TextBlock Text="并行任务" Foreground="#AAB2BE" FontSize="12"/><TextBox x:Name="JobsBox" Text="4" Height="36" Margin="0,5,0,0"/></StackPanel>
        </Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="格式专用参数" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <StackPanel Margin="0,0,6,0"><TextBlock Text="PNG 压缩级别 0-9" Foreground="#AAB2BE" FontSize="12"/><TextBox x:Name="PngCompressionBox" Text="9" Height="36" Margin="0,5,0,0"/></StackPanel>
          <StackPanel Grid.Column="1" Margin="6,0"><TextBlock Text="PNG 调色板颜色 2-256" Foreground="#AAB2BE" FontSize="12"/><TextBox x:Name="PngColorsBox" Text="256" Height="36" Margin="0,5,0,0"/></StackPanel>
          <StackPanel Grid.Column="2" Margin="6,0"><TextBlock Text="GIF 颜色 2-256" Foreground="#AAB2BE" FontSize="12"/><TextBox x:Name="GifColorsBox" Text="256" Height="36" Margin="0,5,0,0"/></StackPanel>
          <StackPanel Grid.Column="3" Margin="6,0"><TextBlock Text="WebP 压缩级别 0-6" Foreground="#AAB2BE" FontSize="12"/><TextBox x:Name="WebpCompressionBox" Text="6" Height="36" Margin="0,5,0,0"/></StackPanel>
          <StackPanel Grid.Column="4" Margin="6,0"><TextBlock Text="动画最高帧率（0保留）" Foreground="#AAB2BE" FontSize="12"/><TextBox x:Name="FpsBox" Text="0" Height="36" Margin="0,5,0,0" ToolTip="只在源 GIF/WebP 帧率更高时降帧；不会给低帧率动画补帧"/></StackPanel>
          <StackPanel Grid.Column="5" Margin="6,0,0,0"><TextBlock Text="单文件超时（秒）" Foreground="#AAB2BE" FontSize="12"/><TextBox x:Name="TimeoutBox" Text="600" Height="36" Margin="0,5,0,0"/></StackPanel>
        </Grid>
        <WrapPanel Margin="0,13,0,0"><CheckBox x:Name="PngPaletteCheck" Content="PNG 调色板有损模式" Margin="0,0,20,0"/><CheckBox x:Name="WebpLosslessCheck" Content="WebP 无损" Margin="0,0,20,0"/><CheckBox x:Name="OnlySmallerCheck" Content="只采用体积更小的结果" IsChecked="True" Margin="0,0,20,0"/><CheckBox x:Name="StripMetadataCheck" Content="移除元数据" Margin="0,0,20,0"/><CheckBox x:Name="AllowUpscaleCheck" Content="允许放大小图" Margin="0,0,20,0"/><CheckBox x:Name="DryRunCheck" Content="仅扫描预览"/></WrapPanel>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12"><TextBlock Text="执行与汇总" FontSize="18" FontWeight="Bold"/><TextBlock x:Name="ResultStatus" Text="等待任务" HorizontalAlignment="Right" Foreground="#777B83" FontSize="14"/></Grid>
        <Grid Margin="0,0,0,12"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="0.45*"/><ColumnDefinition Width="0.45*"/><ColumnDefinition Width="0.45*"/><ColumnDefinition Width="0.45*"/></Grid.ColumnDefinitions><Button x:Name="StartButton" Content="开始压缩" Height="44" Margin="0,0,7,0" Background="#12382D" Foreground="#9DE0C6" FontWeight="Bold"/><Button x:Name="StopButton" Grid.Column="1" Content="停止任务" Height="44" Margin="7,0" Foreground="#F28B94" IsEnabled="False"/><Button x:Name="OpenCsvButton" Grid.Column="2" Content="打开 CSV" Height="44" Margin="7,0" IsEnabled="False"/><Button x:Name="OpenJsonButton" Grid.Column="3" Content="打开 JSON" Height="44" Margin="7,0" IsEnabled="False"/><Button x:Name="OpenOutputSummaryButton" Grid.Column="4" Content="打开输出" Height="44" Margin="7,0,0,0" IsEnabled="False"/></Grid>
        <ProgressBar x:Name="ProgressBar" Height="8" Minimum="0" Maximum="100" Value="0"/>
        <TextBlock x:Name="StatusLine" Text="选择图片或目录后开始；源文件默认保持不变。" Foreground="#8B9099" FontSize="13" Margin="0,9,0,0"/>
        <UniformGrid Columns="6" Margin="0,12,0,0"><Border Background="#15181C" CornerRadius="6" Padding="9" Margin="0,0,4,0"><StackPanel><TextBlock Text="总文件" Foreground="#777B83"/><TextBlock x:Name="TotalCount" Text="0" FontSize="19" FontWeight="Bold"/></StackPanel></Border><Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="已压缩" Foreground="#777B83"/><TextBlock x:Name="CompressedCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#31D69A"/></StackPanel></Border><Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="保留原图" Foreground="#777B83"/><TextBlock x:Name="KeptCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#F4B860"/></StackPanel></Border><Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="失败" Foreground="#777B83"/><TextBlock x:Name="FailedCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#EF7C86"/></StackPanel></Border><Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="节省空间" Foreground="#777B83"/><TextBlock x:Name="SavedSize" Text="0 B" FontSize="19" FontWeight="Bold" Foreground="#72B7F2"/></StackPanel></Border><Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0,0,0"><StackPanel><TextBlock Text="总耗时" Foreground="#777B83"/><TextBlock x:Name="ElapsedTime" Text="0 秒" FontSize="19" FontWeight="Bold"/></StackPanel></Border></UniformGrid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel><Grid Margin="0,0,0,9"><TextBlock Text="逐文件报告" FontSize="18" FontWeight="Bold"/><TextBlock x:Name="FileCounter" Text="0 项" HorizontalAlignment="Right" Foreground="#777B83"/></Grid><DataGrid x:Name="FilesGrid" MinHeight="210" MaxHeight="430" AutoGenerateColumns="False" IsReadOnly="True" CanUserAddRows="False" CanUserDeleteRows="False" HeadersVisibility="Column" GridLinesVisibility="Horizontal" EnableRowVirtualization="True"><DataGrid.Columns><DataGridTextColumn Header="文件名" Binding="{Binding FileName}" Width="2*"/><DataGridTextColumn Header="格式" Binding="{Binding Format}" Width="70"/><DataGridTextColumn Header="原大小" Binding="{Binding OriginalSize}" Width="105"/><DataGridTextColumn Header="新大小" Binding="{Binding NewSize}" Width="105"/><DataGridTextColumn Header="压缩了多少" Binding="{Binding SavedSize}" Width="120"/><DataGridTextColumn Header="压缩率" Binding="{Binding SavedPercent}" Width="85"/><DataGridTextColumn Header="耗时" Binding="{Binding Elapsed}" Width="90"/><DataGridTextColumn Header="状态" Binding="{Binding Status}" Width="155"/></DataGrid.Columns></DataGrid></StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16"><StackPanel><TextBlock Text="任务日志" FontSize="18" FontWeight="Bold" Margin="0,0,0,9"/><TextBox x:Name="LogBox" MinHeight="120" MaxHeight="260" AcceptsReturn="True" TextWrapping="NoWrap" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" IsReadOnly="True" Text="等待任务输出..."/></StackPanel></Border>
  </StackPanel>
</ScrollViewer>
"@

    $root = Import-CkXaml $xaml
    $ui = Get-CkNamedControls -Root $root -Names @(
        'EnvironmentStatus','PythonDot','PythonText','PythonBrowseButton','PythonDownloadButton','FFmpegDot','FFmpegText','FFmpegBrowseButton','FFmpegDownloadButton','ComponentDot','ComponentText',
        'InputBox','ChooseInputFolderButton','ChooseInputFileButton','OutputBox','ChooseOutputButton','OpenOutputButton','RecursiveCheck','InPlaceCheck','OverwriteCheck','BackupGrid','BackupBox','ChooseBackupButton',
        'JpgCheck','PngCheck','GifCheck','WebpCheck','QualityBox','JpgQualityBox','WebpQualityBox','MaxWidthBox','MaxHeightBox','JobsBox','PngCompressionBox','PngColorsBox','GifColorsBox','WebpCompressionBox','FpsBox','TimeoutBox',
        'PngPaletteCheck','WebpLosslessCheck','OnlySmallerCheck','StripMetadataCheck','AllowUpscaleCheck','DryRunCheck','StartButton','StopButton','OpenCsvButton','OpenJsonButton','OpenOutputSummaryButton','ResultStatus','ProgressBar','StatusLine',
        'TotalCount','CompressedCount','KeptCount','FailedCount','SavedSize','ElapsedTime','FileCounter','FilesGrid','LogBox'
    )
    $ui.InputBox.Text = [string]$Context.Paths.DefaultImageCompressorInput
    $ui.OutputBox.Text = [string]$Context.Paths.DefaultImageCompressorOutput
    $ui.FilesGrid.ItemsSource = $rows

    function Get-ImageProperty {
        param($Object, [string]$Name, $Default = $null)
        if ($Object -and $Object.PSObject.Properties[$Name]) { return $Object.$Name }
        return $Default
    }

    function Format-ImageBytes {
        param([long]$Bytes)
        if ([Math]::Abs($Bytes) -ge 1GB) { return ('{0:N2} GiB' -f ($Bytes / 1GB)) }
        if ([Math]::Abs($Bytes) -ge 1MB) { return ('{0:N2} MiB' -f ($Bytes / 1MB)) }
        if ([Math]::Abs($Bytes) -ge 1KB) { return ('{0:N2} KiB' -f ($Bytes / 1KB)) }
        return "$Bytes B"
    }

    function Get-ImagePythonInfo {
        $environment = Get-CkToolboxEnvironment -Context $Context
        $blender = if ($environment.Blender.Ok) { $environment.Blender.Path } else { '' }
        $settings = Get-CkDependencySettings
        return Get-CkPythonInfo -RuntimeRoot $Context.Paths.RuntimeRoot -BlenderExe $blender -ConfiguredPath ([string]$settings.PythonPath)
    }

    function Get-ImageFFmpegInfo {
        $settings = Get-CkDependencySettings
        $candidates = New-Object System.Collections.Generic.List[string]
        if ($settings.FFmpegPath) { $candidates.Add([string]$settings.FFmpegPath) }
        foreach ($command in @(Get-Command ffmpeg.exe -All -ErrorAction SilentlyContinue)) { if ($command.Source) { $candidates.Add([string]$command.Source) } }
        foreach ($candidate in @($candidates | Where-Object { $_ } | Select-Object -Unique)) {
            if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
            $probe = Join-Path (Split-Path -Parent $candidate) 'ffprobe.exe'
            if (-not (Test-Path -LiteralPath $probe -PathType Leaf)) { continue }
            return [pscustomobject]@{ Ok = $true; FFmpeg = [IO.Path]::GetFullPath($candidate); FFprobe = [IO.Path]::GetFullPath($probe); Label = 'FFmpeg / ffprobe 已就绪'; Reason = '' }
        }
        return [pscustomobject]@{ Ok = $false; FFmpeg = ''; FFprobe = ''; Label = '未检测到 FFmpeg'; Reason = '请选择包含 ffmpeg.exe 和 ffprobe.exe 的目录。' }
    }

    function Update-ImageEnvironment {
        $python = & $getPythonInfoAction
        $ffmpeg = & $getFFmpegInfoAction
        $componentOk = Test-Path -LiteralPath $Context.Paths.ImageCompressorScript -PathType Leaf
        Set-CkStatusDot $ui.PythonDot ([bool]$python.Ok)
        Set-CkStatusDot $ui.FFmpegDot ([bool]$ffmpeg.Ok)
        Set-CkStatusDot $ui.ComponentDot $componentOk
        $ui.PythonText.Text = [string]$python.Label
        $ui.PythonText.ToolTip = if ($python.Ok) { [string]$python.Path } else { [string]$python.Reason }
        $ui.FFmpegText.Text = [string]$ffmpeg.Label
        $ui.FFmpegText.ToolTip = if ($ffmpeg.Ok) { [string]$ffmpeg.FFmpeg } else { [string]$ffmpeg.Reason }
        $ui.ComponentText.Text = if ($componentOk) { '图片压缩 CLI 已就绪' } else { '请在顶部安装组件' }
        $ui.ComponentText.ToolTip = [string]$Context.Paths.ImageCompressorScript
        $allOk = $python.Ok -and $ffmpeg.Ok -and $componentOk
        $ui.EnvironmentStatus.Text = if ($allOk) { '运行环境就绪' } else { '请处理缺失项' }
        $ui.EnvironmentStatus.Foreground = if ($allOk) { (Get-CkThemeBrush '#31D69A') } else { (Get-CkThemeBrush '#F4B860') }
    }

    function Set-ImageRunning {
        param([bool]$Running)
        foreach ($control in @($ui.InputBox,$ui.ChooseInputFolderButton,$ui.ChooseInputFileButton,$ui.OutputBox,$ui.ChooseOutputButton,$ui.RecursiveCheck,$ui.InPlaceCheck,$ui.OverwriteCheck,$ui.BackupBox,$ui.ChooseBackupButton,$ui.JpgCheck,$ui.PngCheck,$ui.GifCheck,$ui.WebpCheck,$ui.QualityBox,$ui.JpgQualityBox,$ui.WebpQualityBox,$ui.MaxWidthBox,$ui.MaxHeightBox,$ui.JobsBox,$ui.PngCompressionBox,$ui.PngColorsBox,$ui.GifColorsBox,$ui.WebpCompressionBox,$ui.FpsBox,$ui.TimeoutBox,$ui.PngPaletteCheck,$ui.WebpLosslessCheck,$ui.OnlySmallerCheck,$ui.StripMetadataCheck,$ui.AllowUpscaleCheck,$ui.DryRunCheck,$ui.StartButton,$ui.PythonBrowseButton,$ui.FFmpegBrowseButton)) {
            $control.IsEnabled = -not $Running
        }
        if (-not $Running) {
            $inPlace = [bool]$ui.InPlaceCheck.IsChecked
            $ui.OutputBox.IsEnabled = -not $inPlace
            $ui.ChooseOutputButton.IsEnabled = -not $inPlace
            $ui.BackupGrid.IsEnabled = $inPlace
        }
        $ui.StopButton.IsEnabled = $Running
        if ($Running) {
            $ui.ResultStatus.Text = '正在处理'
            $ui.ResultStatus.Foreground = (Get-CkThemeBrush '#72B7F2')
        }
    }

    function Get-ImageInt {
        param($Box, [string]$Name, [int]$Minimum, [int]$Maximum)
        [int]$value = 0
        if (-not [int]::TryParse($Box.Text.Trim(), [ref]$value) -or $value -lt $Minimum -or $value -gt $Maximum) {
            throw "$Name 必须是 $Minimum 到 $Maximum 的整数。"
        }
        return $value
    }

    function Get-ImageFloat {
        param($Box, [string]$Name, [double]$Minimum, [double]$Maximum)
        [double]$value = 0
        if (-not [double]::TryParse($Box.Text.Trim(), [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$value)) {
            if (-not [double]::TryParse($Box.Text.Trim(), [ref]$value)) { throw "$Name 必须是数字。" }
        }
        if ([double]::IsNaN($value) -or [double]::IsInfinity($value) -or $value -lt $Minimum -or $value -gt $Maximum) { throw "$Name 必须位于 $Minimum 到 $Maximum。" }
        return $value
    }

    function New-ImageReportDirectory {
        $base = Join-Path (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CKFreeToolbox') 'image-compressor-reports'
        $run = (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 6)
        $path = Join-Path $base $run
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        return $path
    }

    function Show-ImageResult {
        param($Payload, [int]$ExitCode)
        $summary = & $getPropertyAction $Payload 'summary' $null
        $ui.TotalCount.Text = [string]([int](& $getPropertyAction $summary 'total' 0))
        $ui.CompressedCount.Text = [string]([int](& $getPropertyAction $summary 'compressed' 0))
        $ui.KeptCount.Text = [string]([int](& $getPropertyAction $summary 'kept_original' 0))
        $ui.FailedCount.Text = [string]([int](& $getPropertyAction $summary 'failed' 0))
        $savedBytes = [long](& $getPropertyAction $summary 'saved_bytes' 0)
        $savedPercent = [double](& $getPropertyAction $summary 'saved_percent' 0)
        $elapsed = [double](& $getPropertyAction $summary 'elapsed_seconds' 0)
        $ui.SavedSize.Text = "$( & $formatBytesAction $savedBytes ) / $($savedPercent.ToString('0.00'))%"
        $ui.ElapsedTime.Text = "$($elapsed.ToString('0.000')) 秒"
        $state.ReportCsv = [string](& $getPropertyAction $Payload 'report_csv' '')
        $state.ReportJson = [string](& $getPropertyAction $Payload 'report_json' '')
        $state.OutputPath = [string](& $getPropertyAction $Payload 'destination' $state.OutputPath)
        $ui.OpenCsvButton.IsEnabled = $state.ReportCsv -and (Test-Path -LiteralPath $state.ReportCsv -PathType Leaf)
        $ui.OpenJsonButton.IsEnabled = $state.ReportJson -and (Test-Path -LiteralPath $state.ReportJson -PathType Leaf)
        $ui.OpenOutputButton.IsEnabled = $state.OutputPath -and (Test-Path -LiteralPath $state.OutputPath)
        $ui.OpenOutputSummaryButton.IsEnabled = $ui.OpenOutputButton.IsEnabled
        $rows.Clear()
        $log = New-Object System.Collections.Generic.List[string]
        foreach ($file in @(& $getPropertyAction $Payload 'files' @())) {
            $statusKey = [string](& $getPropertyAction $file 'status' '')
            $statusText = switch ($statusKey) { 'compressed' { '已压缩' } 'kept_original' { '保留原图' } 'skipped_exists' { '已跳过' } 'dry_run' { '预览' } 'failed' { '失败' } default { $statusKey } }
            $original = [long](& $getPropertyAction $file 'original_size_bytes' 0)
            $newSize = [long](& $getPropertyAction $file 'new_size_bytes' 0)
            $saved = [long](& $getPropertyAction $file 'saved_bytes' 0)
            $ratio = [double](& $getPropertyAction $file 'saved_percent' 0)
            $fileElapsed = [double](& $getPropertyAction $file 'elapsed_seconds' 0)
            $rows.Add([pscustomobject]@{
                FileName = [string](& $getPropertyAction $file 'relative_path' (& $getPropertyAction $file 'file_name' ''))
                Format = [string](& $getPropertyAction $file 'format' '')
                OriginalSize = & $formatBytesAction $original
                NewSize = & $formatBytesAction $newSize
                SavedSize = & $formatBytesAction $saved
                SavedPercent = "$($ratio.ToString('0.00'))%"
                Elapsed = "$($fileElapsed.ToString('0.000')) 秒"
                Status = $statusText
            })
            $errorText = [string](& $getPropertyAction $file 'error' '')
            if ($errorText) { $log.Add("[失败] $([string](& $getPropertyAction $file 'relative_path' '')) · $errorText") }
        }
        $ui.FileCounter.Text = "$($rows.Count) 项"
        if ($state.ReportCsv) { $log.Insert(0, "CSV 报告: $($state.ReportCsv)") }
        if ($state.ReportJson) { $log.Insert([Math]::Min(1, $log.Count), "JSON 报告: $($state.ReportJson)") }
        $ui.LogBox.Text = if ($log.Count) { $log -join [Environment]::NewLine } else { '任务完成，没有单文件错误。' }
        $failed = [int](& $getPropertyAction $summary 'failed' 0)
        $ui.ProgressBar.Value = if ($ExitCode -eq 0) { 100 } else { 96 }
        if ($ExitCode -eq 0 -and $failed -eq 0) {
            $ui.ResultStatus.Text = '处理完成'
            $ui.ResultStatus.Foreground = (Get-CkThemeBrush '#31D69A')
            $ui.StatusLine.Text = "共 $($rows.Count) 个文件，节省 $( & $formatBytesAction $savedBytes )（$($savedPercent.ToString('0.00'))%）。"
        } else {
            $ui.ResultStatus.Text = '任务存在失败'
            $ui.ResultStatus.Foreground = (Get-CkThemeBrush '#EF7C86')
            $ui.StatusLine.Text = "失败 $failed 个；请检查逐文件报告。"
        }
    }

    $getPropertyAction = (Get-Command Get-ImageProperty).ScriptBlock.GetNewClosure()
    $formatBytesAction = (Get-Command Format-ImageBytes).ScriptBlock.GetNewClosure()
    $getPythonInfoAction = (Get-Command Get-ImagePythonInfo).ScriptBlock.GetNewClosure()
    $getFFmpegInfoAction = (Get-Command Get-ImageFFmpegInfo).ScriptBlock.GetNewClosure()
    $updateEnvironmentAction = (Get-Command Update-ImageEnvironment).ScriptBlock.GetNewClosure()
    $setRunningAction = (Get-Command Set-ImageRunning).ScriptBlock.GetNewClosure()
    $getIntAction = (Get-Command Get-ImageInt).ScriptBlock.GetNewClosure()
    $getFloatAction = (Get-Command Get-ImageFloat).ScriptBlock.GetNewClosure()
    $newReportDirectoryAction = (Get-Command New-ImageReportDirectory).ScriptBlock.GetNewClosure()
    $showResultAction = (Get-Command Show-ImageResult).ScriptBlock.GetNewClosure()

    $showPageError = {
        param([string]$message)
        $ui.ResultStatus.Text = '操作失败'
        $ui.ResultStatus.Foreground = (Get-CkThemeBrush '#EF7C86')
        $ui.StatusLine.Text = $message
        Add-CkLogLine -TextBox $ui.LogBox -Line "[工具箱] $message"
        [System.Windows.MessageBox]::Show($message, 'CK免费工具箱 - 图片批量压缩') | Out-Null
    }.GetNewClosure()

    $chooseFolderAction = {
        param($Box, [string]$Description)
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = $Description
        $dialog.ShowNewFolderButton = $true
        Set-CkDialogInitialPath -Dialog $dialog -Path $Box.Text
        try {
            if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return $false }
            $Box.Text = $dialog.SelectedPath
            return $true
        } finally { $dialog.Dispose() }
    }.GetNewClosure()
    $chooseInputFolderAction = {
        if (& $chooseFolderAction $ui.InputBox '选择包含 JPG、PNG、GIF 或 WebP 的目录') {
            $ui.OutputBox.Text = $ui.InputBox.Text.Trim().TrimEnd('\') + '_compressed'
        }
    }.GetNewClosure()
    $chooseInputFileAction = {
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Title = '选择 JPG、PNG、GIF 或 WebP'
        $dialog.Filter = '支持的图片|*.jpg;*.jpeg;*.png;*.gif;*.webp|所有文件|*.*'
        $dialog.CheckFileExists = $true
        Set-CkDialogInitialPath -Dialog $dialog -Path $ui.InputBox.Text
        if ($dialog.ShowDialog() -eq $true) {
            $ui.InputBox.Text = $dialog.FileName
            $ui.OutputBox.Text = Join-Path (Split-Path -Parent $dialog.FileName) (([IO.Path]::GetFileNameWithoutExtension($dialog.FileName)) + '.compressed' + ([IO.Path]::GetExtension($dialog.FileName)))
        }
    }.GetNewClosure()
    $chooseOutputAction = {
        $inputPath = $ui.InputBox.Text.Trim()
        if ($inputPath -and (Test-Path -LiteralPath $inputPath -PathType Leaf)) {
            $dialog = New-Object Microsoft.Win32.SaveFileDialog
            $dialog.Title = '选择压缩输出文件'
            $dialog.Filter = '图片文件|*.jpg;*.jpeg;*.png;*.gif;*.webp|所有文件|*.*'
            Set-CkDialogInitialPath -Dialog $dialog -Path $ui.OutputBox.Text -ForSave
            if ($dialog.ShowDialog() -eq $true) { $ui.OutputBox.Text = $dialog.FileName }
        } else {
            & $chooseFolderAction $ui.OutputBox '选择压缩输出目录'
        }
    }.GetNewClosure()
    $chooseBackupAction = { & $chooseFolderAction $ui.BackupBox '选择原地压缩的备份目录' }.GetNewClosure()

    $updateInPlaceAction = {
        $inPlace = [bool]$ui.InPlaceCheck.IsChecked
        $ui.OutputBox.IsEnabled = -not $inPlace
        $ui.ChooseOutputButton.IsEnabled = -not $inPlace
        $ui.BackupGrid.IsEnabled = $inPlace
    }.GetNewClosure()

    $selectPythonAction = {
        $settings = Get-CkDependencySettings
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Title = '选择 Python 主程序 python.exe'
        $dialog.Filter = 'Python 主程序 (python.exe)|python.exe|可执行文件 (*.exe)|*.exe'
        $dialog.CheckFileExists = $true
        if ($settings.PythonPath -and (Test-Path -LiteralPath ([string]$settings.PythonPath) -PathType Leaf)) { $dialog.InitialDirectory = Split-Path -Parent ([string]$settings.PythonPath); $dialog.FileName = [string]$settings.PythonPath }
        if ($dialog.ShowDialog() -ne $true) { return }
        $selected = [IO.Path]::GetFullPath($dialog.FileName)
        $info = Test-CkPythonExecutable -Path $selected
        if (-not $info.Ok) { throw [string]$info.Reason }
        [void](Set-CkDependencyPath -Dependency Python -Path $selected)
        & $updateEnvironmentAction
    }.GetNewClosure()
    $selectFFmpegAction = {
        $settings = Get-CkDependencySettings
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Title = '选择 ffmpeg.exe（同目录必须包含 ffprobe.exe）'
        $dialog.Filter = 'FFmpeg (ffmpeg.exe)|ffmpeg.exe|可执行文件 (*.exe)|*.exe'
        $dialog.CheckFileExists = $true
        if ($settings.FFmpegPath -and (Test-Path -LiteralPath ([string]$settings.FFmpegPath) -PathType Leaf)) { $dialog.InitialDirectory = Split-Path -Parent ([string]$settings.FFmpegPath); $dialog.FileName = [string]$settings.FFmpegPath }
        if ($dialog.ShowDialog() -ne $true) { return }
        $selected = [IO.Path]::GetFullPath($dialog.FileName)
        $probe = Join-Path (Split-Path -Parent $selected) 'ffprobe.exe'
        if (-not (Test-Path -LiteralPath $probe -PathType Leaf)) { throw "ffmpeg.exe 同目录缺少 ffprobe.exe：$probe" }
        [void](Set-CkDependencyPath -Dependency FFmpeg -Path $selected)
        & $updateEnvironmentAction
    }.GetNewClosure()

    $openPathAction = {
        param([string]$Path)
        if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { throw '路径尚不存在。' }
        if (Test-Path -LiteralPath $Path -PathType Leaf) { Start-Process -FilePath $Path } else { Start-Process -FilePath 'explorer.exe' -ArgumentList @([IO.Path]::GetFullPath($Path)) }
    }.GetNewClosure()

    $startAction = {
        if ($state.Process -and -not $state.Process.Process.HasExited) { throw '已有图片压缩任务正在运行。' }
        if (-not (Test-Path -LiteralPath $Context.Paths.ImageCompressorScript -PathType Leaf)) { throw '组件未安装，请先点击顶部“安装组件”。' }
        $pythonInfo = & $getPythonInfoAction
        if (-not $pythonInfo.Ok) { throw [string]$pythonInfo.Reason }
        $ffmpegInfo = & $getFFmpegInfoAction
        if (-not $ffmpegInfo.Ok) { throw [string]$ffmpegInfo.Reason }
        $inputPath = $ui.InputBox.Text.Trim()
        if (-not $inputPath -or -not (Test-Path -LiteralPath $inputPath)) { throw '请选择存在的输入文件或目录。' }
        $inputPath = [IO.Path]::GetFullPath($inputPath)
        $inPlace = [bool]$ui.InPlaceCheck.IsChecked
        $outputPath = $ui.OutputBox.Text.Trim()
        if (-not $inPlace) {
            if (-not $outputPath) { throw '请选择输出文件或目录。' }
            $outputPath = [IO.Path]::GetFullPath($outputPath)
            if ($outputPath -eq $inputPath) { throw '输出不能等于输入；需要原地压缩时请勾选对应选项。' }
        } else {
            $answer = [System.Windows.MessageBox]::Show("即将原地压缩：`n$inputPath`n`n工具会先在输入路径外建立备份。是否继续？", '确认原地压缩', [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
            if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
            $outputPath = $inputPath
        }
        $formats = New-Object System.Collections.Generic.List[string]
        if ($ui.JpgCheck.IsChecked) { $formats.Add('jpg'); $formats.Add('jpeg') }
        if ($ui.PngCheck.IsChecked) { $formats.Add('png') }
        if ($ui.GifCheck.IsChecked) { $formats.Add('gif') }
        if ($ui.WebpCheck.IsChecked) { $formats.Add('webp') }
        if (-not $formats.Count) { throw '至少选择一种图片格式。' }

        $quality = & $getIntAction $ui.QualityBox '通用画质' 1 100
        $jpgQuality = & $getIntAction $ui.JpgQualityBox 'JPG 画质' 1 100
        $webpQuality = & $getIntAction $ui.WebpQualityBox 'WebP 画质' 1 100
        $maxWidth = & $getIntAction $ui.MaxWidthBox '最大宽度' 0 100000
        $maxHeight = & $getIntAction $ui.MaxHeightBox '最大高度' 0 100000
        $jobs = & $getIntAction $ui.JobsBox '并行任务' 1 64
        $pngCompression = & $getIntAction $ui.PngCompressionBox 'PNG 压缩级别' 0 9
        $pngColors = & $getIntAction $ui.PngColorsBox 'PNG 颜色数' 2 256
        $gifColors = & $getIntAction $ui.GifColorsBox 'GIF 颜色数' 2 256
        $webpCompression = & $getIntAction $ui.WebpCompressionBox 'WebP 压缩级别' 0 6
        $fps = & $getFloatAction $ui.FpsBox '动画最高帧率' 0 1000
        $timeout = & $getIntAction $ui.TimeoutBox '单文件超时' 1 86400
        $reportDir = & $newReportDirectoryAction
        $args = @('-u', $Context.Paths.ImageCompressorScript, $inputPath, '--json', '--progress', '--report-dir', $reportDir, '--formats') + @($formats)
        $args += @('--quality', $quality, '--jpg-quality', $jpgQuality, '--webp-quality', $webpQuality, '--png-compression', $pngCompression, '--png-colors', $pngColors, '--gif-colors', $gifColors, '--webp-compression', $webpCompression, '--max-width', $maxWidth, '--max-height', $maxHeight, '--jobs', $jobs, '--timeout', $timeout, '--ffmpeg', $ffmpegInfo.FFmpeg, '--ffprobe', $ffmpegInfo.FFprobe)
        if ($fps -gt 0) { $args += @('--fps', $fps.ToString([Globalization.CultureInfo]::InvariantCulture)) }
        if ($ui.PngPaletteCheck.IsChecked) { $args += @('--png-mode', 'palette') }
        if ($ui.WebpLosslessCheck.IsChecked) { $args += '--webp-lossless' }
        if ($ui.OnlySmallerCheck.IsChecked) { $args += '--only-smaller' } else { $args += '--allow-larger' }
        if ($ui.StripMetadataCheck.IsChecked) { $args += '--strip-metadata' }
        if ($ui.AllowUpscaleCheck.IsChecked) { $args += '--allow-upscale' }
        if ($ui.OverwriteCheck.IsChecked) { $args += '--overwrite' }
        if ($ui.DryRunCheck.IsChecked) { $args += '--dry-run' }
        if ((Test-Path -LiteralPath $inputPath -PathType Container) -and $ui.RecursiveCheck.IsChecked) { $args += '--recursive' }
        if ($inPlace) {
            $args += '--in-place'
            if ($ui.BackupBox.Text.Trim()) { $args += @('--backup-dir', [IO.Path]::GetFullPath($ui.BackupBox.Text.Trim())) }
        } else {
            $args += @('--output', $outputPath)
        }

        $state.CancelRequested = $false
        $state.ReportCsv = ''
        $state.ReportJson = ''
        $state.OutputPath = $outputPath
        $rows.Clear()
        $ui.FileCounter.Text = '0 项'
        foreach ($counter in @($ui.TotalCount,$ui.CompressedCount,$ui.KeptCount,$ui.FailedCount)) { $counter.Text = '0' }
        $ui.SavedSize.Text = '0 B'
        $ui.ElapsedTime.Text = '0 秒'
        $ui.ProgressBar.Value = 0
        $ui.LogBox.Text = ''
        $ui.OpenCsvButton.IsEnabled = $false
        $ui.OpenJsonButton.IsEnabled = $false
        $ui.OpenOutputButton.IsEnabled = $false
        $ui.OpenOutputSummaryButton.IsEnabled = $false
        & $setRunningAction $true

        $output = New-Object Text.StringBuilder
        $callbackOutput = $output
        $callbackState = $state
        $callbackUi = $ui
        $callbackShowResult = $showResultAction
        $callbackSetRunning = $setRunningAction
        $onOutput = {
            param($line)
            if ($line -and $line.StartsWith('CK_PROGRESS ', [StringComparison]::Ordinal)) {
                $progress = $null
                try { $progress = $line.Substring(12) | ConvertFrom-Json } catch { }
                if ($progress) {
                    $callbackUi.ProgressBar.Value = [Math]::Max(0, [Math]::Min(100, [double]$progress.percent))
                    $callbackUi.StatusLine.Text = [string]$progress.message
                }
                return
            }
            [void]$callbackOutput.AppendLine($line)
        }.GetNewClosure()
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
            } else {
                $callbackUi.ResultStatus.Text = if ($cancelled) { '任务已停止' } else { '结果解析失败' }
                $callbackUi.ResultStatus.Foreground = if ($cancelled) { (Get-CkThemeBrush '#F4B860') } else { (Get-CkThemeBrush '#EF7C86') }
                $callbackUi.StatusLine.Text = if ($cancelled) { '任务已由用户停止。' } else { "进程退出码: $exitCode" }
                $callbackUi.LogBox.Text = if ($raw) { $raw } else { '组件没有返回 JSON 结果。' }
            }
        }.GetNewClosure()
        $onProcessError = { param($message) $callbackUi.StatusLine.Text = $message }.GetNewClosure()
        try {
            $state.Process = Start-CkLoggedProcess -FileName ([string]$pythonInfo.Path) -Arguments $args -WorkingDirectory $Context.Paths.ImageCompressorDir -Dispatcher $Context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onProcessError
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
        $ui.StatusLine.Text = '正在停止 Python 和 FFmpeg 子进程...'
        $pidToStop = $state.Process.Process.Id
        $killerInfo = New-Object Diagnostics.ProcessStartInfo
        $killerInfo.FileName = 'taskkill.exe'
        $killerInfo.Arguments = "/PID $pidToStop /T /F"
        $killerInfo.UseShellExecute = $false
        $killerInfo.CreateNoWindow = $true
        $killer = [Diagnostics.Process]::Start($killerInfo)
        if ($killer) { [void]$killer.WaitForExit(5000); $killer.Dispose() }
    }.GetNewClosure()

    $openOutputAction = { & $openPathAction $state.OutputPath }.GetNewClosure()
    $openCsvAction = { & $openPathAction $state.ReportCsv }.GetNewClosure()
    $openJsonAction = { & $openPathAction $state.ReportJson }.GetNewClosure()

    $ui.InPlaceCheck.Add_Checked($updateInPlaceAction)
    $ui.InPlaceCheck.Add_Unchecked($updateInPlaceAction)
    Register-CkButtonAction -Button $ui.PythonDownloadButton -Action { Start-Process -FilePath 'https://www.python.org/downloads/windows/' } -OnError $showPageError
    Register-CkButtonAction -Button $ui.FFmpegDownloadButton -Action { Start-Process -FilePath 'https://ffmpeg.org/download.html#build-windows' } -OnError $showPageError
    Register-CkButtonAction -Button $ui.PythonBrowseButton -Action $selectPythonAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.FFmpegBrowseButton -Action $selectFFmpegAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseInputFolderButton -Action $chooseInputFolderAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseInputFileButton -Action $chooseInputFileAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseOutputButton -Action $chooseOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseBackupButton -Action $chooseBackupAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StartButton -Action $startAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StopButton -Action $stopAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenOutputButton -Action $openOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenOutputSummaryButton -Action $openOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenCsvButton -Action $openCsvAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenJsonButton -Action $openJsonAction -OnError $showPageError

    & $updateInPlaceAction
    & $updateEnvironmentAction
    return [pscustomobject]@{
        Id = 'image-compressor'
        Title = '图片批量压缩'
        Icon = '▤'
        Root = $root
        Activate = $updateEnvironmentAction
    }
}
