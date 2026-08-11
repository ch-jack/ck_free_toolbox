function New-CkSnowyMergerPage {
    param([Parameter(Mandatory)]$Context)

    $state = [pscustomobject]@{
        Process = $null
        CancelRequested = $false
        ConflictCount = 0
        ResolvedCount = 0
        NoConflicts = $false
        ReportPath = ''
        StartedAt = $null
        GtaPath = ''
        InputPath = ''
        OutputPath = ''
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
            <Border Width="4" Height="22" CornerRadius="3" Background="#8B7CF6" Margin="0,0,10,0"/>
            <StackPanel>
              <TextBlock Text="地图冲突合并" FontSize="21" FontWeight="Bold"/>
              <TextBlock Text="SnowyMerger · 合并冲突地图并生成可直接启动的 FiveM resource" Foreground="#777B83" FontSize="12" Margin="0,4,0,0"/>
            </StackPanel>
          </StackPanel>
          <TextBlock x:Name="EnvironmentStatus" Text="检测中" HorizontalAlignment="Right" VerticalAlignment="Center" Foreground="#F4B860" FontSize="14" FontWeight="SemiBold"/>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Border Grid.Column="0" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="0,0,5,0">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/><ColumnDefinition Width="48"/></Grid.ColumnDefinitions><Ellipse x:Name="DotNetDot" Width="9" Height="9" Fill="#F4B860" VerticalAlignment="Center"/><StackPanel Grid.Column="1"><TextBlock Text=".NET 8 Runtime" FontSize="14" FontWeight="SemiBold"/><TextBlock x:Name="DotNetText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel><Button x:Name="DotNetButton" Grid.Column="2" Content="官网" Height="27" Foreground="#58A6FF"/></Grid>
          </Border>
          <Border Grid.Column="1" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="5,0">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Ellipse x:Name="ComponentDot" Width="9" Height="9" Fill="#F4B860" VerticalAlignment="Center"/><StackPanel Grid.Column="1"><TextBlock Text="SnowyMerger 组件" FontSize="14" FontWeight="SemiBold"/><TextBlock x:Name="ComponentText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel></Grid>
          </Border>
          <Border Grid.Column="2" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="5,0,0,0">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Ellipse x:Name="GtaDot" Width="9" Height="9" Fill="#F4B860" VerticalAlignment="Center"/><StackPanel Grid.Column="1"><TextBlock Text="GTA V 本体" FontSize="14" FontWeight="SemiBold"/><TextBlock x:Name="GtaText" Text="等待选择" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel></Grid>
          </Border>
        </Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="输入与输出" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid Margin="0,0,0,10">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="88"/><ColumnDefinition Width="88"/></Grid.ColumnDefinitions>
          <StackPanel><TextBlock Text="GTA V 安装目录" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="GtaBox" AutomationProperties.AutomationId="SnowyMerger.GtaBox" Height="36"/></StackPanel>
          <Button x:Name="AutoDetectGtaButton" Grid.Column="1" Content="自动检测" Height="36" Margin="7,22,0,0" Background="#173055" Foreground="#58A6FF"/>
          <Button x:Name="ChooseGtaButton" Grid.Column="2" Content="选择目录" Height="36" Margin="7,22,0,0"/>
        </Grid>
        <Grid Margin="0,0,0,10">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="88"/></Grid.ColumnDefinitions>
          <StackPanel><TextBlock Text="地图 Mods 目录（包含两个或更多 FiveM resources）" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="InputBox" AutomationProperties.AutomationId="SnowyMerger.InputBox" Height="36"/></StackPanel>
          <Button x:Name="ChooseInputButton" Grid.Column="1" Content="选择目录" Height="36" Margin="7,22,0,0" Background="#173055" Foreground="#58A6FF"/>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="88"/><ColumnDefinition Width="88"/></Grid.ColumnDefinitions>
          <StackPanel><TextBlock Text="输出父目录（将生成 snowy_merger resource）" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="OutputBox" AutomationProperties.AutomationId="SnowyMerger.OutputBox" Height="36"/></StackPanel>
          <Button x:Name="ChooseOutputButton" Grid.Column="1" Content="选择目录" Height="36" Margin="7,22,0,0" Background="#173055" Foreground="#58A6FF"/>
          <Button x:Name="OpenOutputButton" Grid.Column="2" Content="打开输出" Height="36" Margin="7,22,0,0"/>
        </Grid>
      </StackPanel>
    </Border>

    <Border Background="#11131A" BorderBrush="#353051" BorderThickness="1" CornerRadius="8" Padding="14" Margin="0,0,0,14">
      <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="28"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><TextBlock Text="i" Foreground="#A99CFF" FontSize="18" FontWeight="Bold" VerticalAlignment="Top"/><StackPanel Grid.Column="1"><TextBlock Text="合并规则" Foreground="#D5D0FF" FontSize="13" FontWeight="SemiBold"/><TextBlock Text="以原版 GTA V 为基线合并重复 YMAP，并同步处理对应 YBN/YDR、scenario YMT、META、water.xml 与 heightmap.dat。实体冲突采用后加载的 Mod；FXAP 保护文件会跳过。" Foreground="#8F91A1" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0"/><TextBlock Text="完成后让 snowy_merger 晚于被替代的地图资源启动，并处理原资源中的重复冲突文件。" Foreground="#F4B860" FontSize="12" TextWrapping="Wrap" Margin="0,5,0,0"/></StackPanel></Grid>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12"><TextBlock Text="合并任务" FontSize="18" FontWeight="Bold"/><TextBlock x:Name="ResultStatus" Text="等待任务" HorizontalAlignment="Right" Foreground="#777B83" FontSize="13" VerticalAlignment="Center"/></Grid>
        <Grid Margin="0,0,0,12">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Border Grid.Column="0" Background="#15181C" CornerRadius="6" Padding="10" Margin="0,0,5,0"><StackPanel><TextBlock Text="发现冲突" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="ConflictCount" Text="0" FontSize="20" FontWeight="Bold" Foreground="#F4B860"/></StackPanel></Border>
          <Border Grid.Column="1" Background="#15181C" CornerRadius="6" Padding="10" Margin="5,0,0,0"><StackPanel><TextBlock Text="已处理文件组" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="ResolvedCount" Text="0" FontSize="20" FontWeight="Bold" Foreground="#31D69A"/></StackPanel></Border>
        </Grid>
        <ProgressBar x:Name="ProgressBar" Height="8" Minimum="0" Maximum="100" Value="0"/>
        <TextBlock x:Name="StatusLine" Text="选择三个目录后开始合并。" Foreground="#8B9099" FontSize="13" Margin="0,9,0,12"/>
        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions><Button x:Name="StartButton" Content="开始合并冲突" Height="44" Margin="0,0,7,0" Background="#124834" Foreground="#54E0A9" FontSize="15" FontWeight="Bold"/><Button x:Name="StopButton" Grid.Column="1" Content="停止任务" Height="44" Margin="7,0,0,0" Foreground="#F28B94" IsEnabled="False"/></Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16">
      <StackPanel><Grid Margin="0,0,0,9"><TextBlock Text="任务日志" FontSize="18" FontWeight="Bold"/><Button x:Name="OpenReportButton" Content="打开本次日志" Height="28" HorizontalAlignment="Right" IsEnabled="False"/></Grid><TextBox x:Name="LogBox" AutomationProperties.AutomationId="SnowyMerger.LogBox" MinHeight="190" MaxHeight="380" AcceptsReturn="True" TextWrapping="NoWrap" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" IsReadOnly="True" Text="等待任务输出..."/></StackPanel>
    </Border>
  </StackPanel>
</ScrollViewer>
"@

    $root = Import-CkXaml $xaml
    $ui = Get-CkNamedControls -Root $root -Names @(
        'EnvironmentStatus','DotNetDot','DotNetText','DotNetButton','ComponentDot','ComponentText','GtaDot','GtaText',
        'GtaBox','AutoDetectGtaButton','ChooseGtaButton','InputBox','ChooseInputButton','OutputBox','ChooseOutputButton','OpenOutputButton',
        'ResultStatus','ConflictCount','ResolvedCount','ProgressBar','StatusLine','StartButton','StopButton','OpenReportButton','LogBox'
    )
    $ui.OutputBox.Text = [string]$Context.Paths.DefaultSnowyMergerOutput

    $testGtaPathAction = {
        param([string]$Path)
        if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
        return (
            (Test-Path -LiteralPath (Join-Path $Path 'GTA5.exe') -PathType Leaf) -or
            (Test-Path -LiteralPath (Join-Path $Path 'PlayGTAV.exe') -PathType Leaf)
        )
    }.GetNewClosure()

    $findGtaPathAction = {
        $registryCandidates = @(
            @('HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\Grand Theft Auto V', 'InstallFolder'),
            @('HKLM:\SOFTWARE\Rockstar Games\Grand Theft Auto V', 'InstallFolder'),
            @('HKLM:\SOFTWARE\WOW6432Node\EpicGames\GTA5', 'AppDataPath')
        )
        foreach ($candidate in $registryCandidates) {
            try {
                $value = Get-ItemPropertyValue -LiteralPath $candidate[0] -Name $candidate[1] -ErrorAction Stop
                if (& $testGtaPathAction ([string]$value)) {
                    return [IO.Path]::GetFullPath([string]$value).TrimEnd('\')
                }
            } catch { }
        }

        foreach ($drive in @(Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
            if (-not $drive.Root) { continue }
            foreach ($relative in @(
                'SteamLibrary\steamapps\common\Grand Theft Auto V',
                'Program Files (x86)\Steam\steamapps\common\Grand Theft Auto V',
                'Program Files\Rockstar Games\Grand Theft Auto V',
                'Epic Games\GTAV'
            )) {
                $candidatePath = Join-Path $drive.Root $relative
                if (& $testGtaPathAction $candidatePath) {
                    return [IO.Path]::GetFullPath($candidatePath).TrimEnd('\')
                }
            }
        }
        return ''
    }.GetNewClosure()

    $setRunningAction = {
        param([bool]$Running)
        foreach ($control in @(
            $ui.GtaBox,$ui.AutoDetectGtaButton,$ui.ChooseGtaButton,
            $ui.InputBox,$ui.ChooseInputButton,$ui.OutputBox,$ui.ChooseOutputButton,$ui.StartButton
        )) {
            $control.IsEnabled = -not $Running
        }
        $ui.StopButton.IsEnabled = $Running
        if ($Running) {
            $ui.ProgressBar.Value = 5
            $ui.ResultStatus.Text = '正在合并'
            $ui.ResultStatus.Foreground = '#72B7F2'
            $ui.StatusLine.Text = '正在扫描冲突并读取 GTA V 原版文件，请勿关闭工具箱。'
        }
    }.GetNewClosure()

    $updateEnvironmentAction = {
        if (-not $ui.GtaBox.Text.Trim()) {
            $detected = & $findGtaPathAction
            if ($detected) { $ui.GtaBox.Text = $detected }
        }

        $environment = Get-CkToolboxEnvironment -Context $Context
        $componentOk = (
            (Test-Path -LiteralPath $Context.Paths.SnowyMergerExe -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $Context.Paths.SnowyMergerDir 'YmapMerger.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $Context.Paths.SnowyMergerDir 'YmapMerger.runtimeconfig.json') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $Context.Paths.SnowyMergerDir 'CodeWalker.Core.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $Context.Paths.SnowyMergerDir 'Aprillz.MewUI.dll') -PathType Leaf)
        )
        $gtaOk = & $testGtaPathAction $ui.GtaBox.Text.Trim()
        Set-CkStatusDot $ui.DotNetDot $environment.DotNet8.Ok
        Set-CkStatusDot $ui.ComponentDot $componentOk
        Set-CkStatusDot $ui.GtaDot $gtaOk
        $ui.DotNetText.Text = [string]$environment.DotNet8.Label
        $ui.ComponentText.Text = if ($componentOk) { 'YmapMerger 与 MewUI 已就绪' } else { '请在顶部安装组件' }
        $ui.GtaText.Text = if ($gtaOk) { '已识别 GTA5.exe' } else { '未识别 GTA V 安装目录' }
        $ui.GtaText.ToolTip = $ui.GtaBox.Text.Trim()

        $allOk = $environment.DotNet8.Ok -and $componentOk -and $gtaOk
        $ui.EnvironmentStatus.Text = if ($allOk) { '运行环境就绪' } else { '请处理缺失项' }
        $ui.EnvironmentStatus.Foreground = if ($allOk) { '#31D69A' } else { '#F4B860' }
    }.GetNewClosure()

    $saveReportAction = {
        $reportRoot = Join-Path (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CKFreeToolbox') 'snowy-merger-reports'
        New-Item -ItemType Directory -Path $reportRoot -Force | Out-Null
        $reportPath = Join-Path $reportRoot ((Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-snowy-merger.log')
        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add('CK免费工具箱 - SnowyMerger 任务日志')
        $lines.Add("开始时间: $($state.StartedAt)")
        $lines.Add("GTA V: $($state.GtaPath)")
        $lines.Add("输入: $($state.InputPath)")
        $lines.Add("输出: $($state.OutputPath)")
        $lines.Add("发现冲突: $($state.ConflictCount)")
        $lines.Add("已处理文件组: $($state.ResolvedCount)")
        $lines.Add('')
        $lines.Add($state.Output.ToString().TrimEnd())
        [IO.File]::WriteAllText(
            $reportPath,
            ($lines -join [Environment]::NewLine),
            (New-Object Text.UTF8Encoding($false))
        )
        $state.ReportPath = $reportPath
        $ui.OpenReportButton.IsEnabled = $true
        return $reportPath
    }.GetNewClosure()

    $showPageError = {
        param([string]$Message)
        $ui.ResultStatus.Text = '操作失败'
        $ui.ResultStatus.Foreground = '#EF7C86'
        $ui.StatusLine.Text = $Message
        Add-CkLogLine -TextBox $ui.LogBox -Line "[工具箱] $Message"
        [System.Windows.MessageBox]::Show($Message, 'CK免费工具箱 - 地图冲突合并') | Out-Null
    }.GetNewClosure()

    $autoDetectGtaAction = {
        $detected = & $findGtaPathAction
        if (-not $detected) { throw '未自动找到 GTA V，请手动选择包含 GTA5.exe 的安装目录。' }
        $ui.GtaBox.Text = $detected
        & $updateEnvironmentAction
    }.GetNewClosure()

    $chooseFolderAction = {
        param($TextBox, [string]$Description, [bool]$AllowCreate)
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = $Description
        $dialog.SelectedPath = $TextBox.Text.Trim()
        $dialog.ShowNewFolderButton = $AllowCreate
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $TextBox.Text = $dialog.SelectedPath
                & $updateEnvironmentAction
            }
        } finally {
            $dialog.Dispose()
        }
    }.GetNewClosure()

    $chooseGtaAction = {
        & $chooseFolderAction $ui.GtaBox '选择 GTA V 安装目录' $false
    }.GetNewClosure()
    $chooseInputAction = {
        & $chooseFolderAction $ui.InputBox '选择包含 FiveM 地图 resources 的目录' $false
    }.GetNewClosure()
    $chooseOutputAction = {
        & $chooseFolderAction $ui.OutputBox '选择 snowy_merger 的输出父目录' $true
    }.GetNewClosure()
    $openDotNetAction = {
        Start-Process -FilePath 'https://dotnet.microsoft.com/download/dotnet/8.0'
    }.GetNewClosure()

    $openOutputAction = {
        $basePath = $ui.OutputBox.Text.Trim()
        $resourcePath = if ($basePath) { Join-Path $basePath 'snowy_merger' } else { '' }
        $path = if ($resourcePath -and (Test-Path -LiteralPath $resourcePath -PathType Container)) {
            $resourcePath
        } else {
            $basePath
        }
        if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Container)) {
            throw "输出目录不存在: $path"
        }
        Start-Process -FilePath explorer.exe -ArgumentList @($path)
    }.GetNewClosure()

    $openReportAction = {
        if (-not $state.ReportPath -or -not (Test-Path -LiteralPath $state.ReportPath -PathType Leaf)) {
            throw '本次任务日志不存在。'
        }
        Start-Process -FilePath notepad.exe -ArgumentList @($state.ReportPath)
    }.GetNewClosure()

    $startAction = {
        if ($state.Process -and -not $state.Process.Process.HasExited) {
            throw '已有 SnowyMerger 任务正在运行。'
        }
        if (
            -not (Test-Path -LiteralPath $Context.Paths.SnowyMergerExe -PathType Leaf) -or
            -not (Test-Path -LiteralPath (Join-Path $Context.Paths.SnowyMergerDir 'YmapMerger.runtimeconfig.json') -PathType Leaf) -or
            -not (Test-Path -LiteralPath (Join-Path $Context.Paths.SnowyMergerDir 'Aprillz.MewUI.dll') -PathType Leaf)
        ) {
            throw 'SnowyMerger 组件未安装或不完整，请先点击顶部“安装组件”。'
        }

        $environment = Get-CkToolboxEnvironment -Context $Context
        if (-not $environment.DotNet8.Ok) {
            throw '运行 SnowyMerger 需要 .NET 8 Runtime。'
        }

        $gtaPath = $ui.GtaBox.Text.Trim()
        if (-not (& $testGtaPathAction $gtaPath)) {
            throw '请选择包含 GTA5.exe 或 PlayGTAV.exe 的 GTA V 安装目录。'
        }
        $gtaPath = [IO.Path]::GetFullPath($gtaPath).TrimEnd('\')

        $inputPath = $ui.InputBox.Text.Trim()
        if (-not $inputPath -or -not (Test-Path -LiteralPath $inputPath -PathType Container)) {
            throw '请选择存在的地图 Mods 目录。'
        }
        $inputPath = [IO.Path]::GetFullPath($inputPath).TrimEnd('\')
        $inputRoot = [IO.Path]::GetPathRoot($inputPath)
        if ($inputRoot -and $inputPath.Equals($inputRoot.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)) {
            throw '不能扫描整个磁盘，请选择具体的地图资源目录。'
        }

        $outputPath = $ui.OutputBox.Text.Trim()
        if (-not $outputPath) { throw '请选择输出父目录。' }
        $outputPath = [IO.Path]::GetFullPath($outputPath).TrimEnd('\')
        $outputRoot = [IO.Path]::GetPathRoot($outputPath)
        if ($outputRoot -and $outputPath.Equals($outputRoot.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)) {
            throw '不能直接输出到磁盘根目录。'
        }
        New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

        $resourcePath = Join-Path $outputPath 'snowy_merger'
        if (Test-Path -LiteralPath $resourcePath -PathType Container) {
            $nl = [Environment]::NewLine
            $answer = [System.Windows.MessageBox]::Show(
                "输出中已存在 snowy_merger。新结果会覆盖同名文件，但不会自动删除旧的无关文件。$nl$nl$resourcePath$nl$nl是否继续？",
                '确认覆盖地图合并结果',
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
        }

        $state.CancelRequested = $false
        $state.ConflictCount = 0
        $state.ResolvedCount = 0
        $state.NoConflicts = $false
        $state.ReportPath = ''
        $state.StartedAt = Get-Date
        $state.GtaPath = $gtaPath
        $state.InputPath = $inputPath
        $state.OutputPath = $outputPath
        $state.Output = New-Object Text.StringBuilder

        $ui.ConflictCount.Text = '0'
        $ui.ResolvedCount.Text = '0'
        $ui.OpenReportButton.IsEnabled = $false
        $ui.LogBox.Text = (
            @(
                '开始 SnowyMerger 合并任务...'
                "GTA V: $gtaPath"
                "输入: $inputPath"
                "输出: $outputPath"
            ) -join [Environment]::NewLine
        )
        & $setRunningAction $true

        $callbackState = $state
        $callbackUi = $ui
        $callbackSetRunning = $setRunningAction
        $callbackSaveReport = $saveReportAction
        $callbackUpdateEnvironment = $updateEnvironmentAction

        $onOutput = {
            param($Line)
            [void]$callbackState.Output.AppendLine([string]$Line)
            Add-CkLogLine -TextBox $callbackUi.LogBox -Line ([string]$Line)

            if ($Line -match '^Found (?<count>\d+) conflict') {
                $callbackState.ConflictCount = [int]$Matches.count
                $callbackUi.ConflictCount.Text = [string]$callbackState.ConflictCount
                $callbackUi.ProgressBar.Value = 15
                $callbackUi.StatusLine.Text = "发现 $($callbackState.ConflictCount) 个 YMAP 冲突，正在提取原版文件。"
            } elseif ($Line -match 'No conflicts found') {
                $callbackState.NoConflicts = $true
                $callbackUi.ProgressBar.Value = 100
                $callbackUi.StatusLine.Text = '没有发现重复 YMAP，无需生成合并资源。'
            } elseif ($Line -match 'Scanning GTA RPF') {
                $callbackUi.ProgressBar.Value = 25
                $callbackUi.StatusLine.Text = '正在扫描 GTA V RPF 并提取原版基线。'
            } elseif ($Line -match '^Extracted \d+ vanilla') {
                $callbackUi.ProgressBar.Value = 45
            } elseif ($Line -match '^\[ok\]') {
                $callbackState.ResolvedCount++
                $callbackUi.ResolvedCount.Text = [string]$callbackState.ResolvedCount
                $callbackUi.ProgressBar.Value = [Math]::Min(88, 55 + ($callbackState.ResolvedCount * 2))
            } elseif ($Line -match 'Writing resource') {
                $callbackUi.ProgressBar.Value = 92
                $callbackUi.StatusLine.Text = '正在写入 snowy_merger resource。'
            } elseif ($Line -match '^Done\. Output:') {
                $callbackUi.ProgressBar.Value = 100
            }
        }.GetNewClosure()

        $onProcessError = {
            param($Message)
            $callbackUi.StatusLine.Text = [string]$Message
        }.GetNewClosure()

        $onExit = {
            param($ExitCode)
            $cancelled = $callbackState.CancelRequested
            $callbackState.CancelRequested = $false
            $callbackState.Process = $null
            & $callbackSetRunning $false

            $reportPath = ''
            try { $reportPath = & $callbackSaveReport } catch { }

            if ($cancelled) {
                $callbackUi.ProgressBar.Value = 0
                $callbackUi.ResultStatus.Text = '任务已停止'
                $callbackUi.ResultStatus.Foreground = '#F4B860'
                $callbackUi.StatusLine.Text = 'SnowyMerger 已停止；已经写出的文件不会自动回滚。'
            } elseif ($ExitCode -ne 0) {
                $callbackUi.ProgressBar.Value = 0
                $callbackUi.ResultStatus.Text = '合并失败'
                $callbackUi.ResultStatus.Foreground = '#EF7C86'
                $callbackUi.StatusLine.Text = "SnowyMerger 退出码: $ExitCode。请查看本次日志。"
            } elseif ($callbackState.NoConflicts) {
                $callbackUi.ResultStatus.Text = '未发现冲突'
                $callbackUi.ResultStatus.Foreground = '#F4B860'
                $callbackUi.StatusLine.Text = '输入目录没有重复 YMAP；未生成新的 snowy_merger resource。'
            } elseif (Test-Path -LiteralPath (Join-Path $callbackState.OutputPath 'snowy_merger') -PathType Container) {
                $callbackUi.ProgressBar.Value = 100
                $callbackUi.ResultStatus.Text = '合并完成'
                $callbackUi.ResultStatus.Foreground = '#31D69A'
                $callbackUi.StatusLine.Text = 'snowy_merger 已生成；请检查日志中的跳过项与冲突策略。'
            } else {
                $callbackUi.ResultStatus.Text = '未生成输出'
                $callbackUi.ResultStatus.Foreground = '#F4B860'
                $callbackUi.StatusLine.Text = '进程正常结束，但没有找到 snowy_merger 输出目录。'
            }

            if ($reportPath) {
                Add-CkLogLine -TextBox $callbackUi.LogBox -Line "[工具箱] 本次日志: $reportPath"
            }
            & $callbackUpdateEnvironment
        }.GetNewClosure()

        try {
            $arguments = @('-g', $gtaPath, '-i', $inputPath, '-o', $outputPath)
            $state.Process = Start-CkLoggedProcess -FileName $Context.Paths.SnowyMergerExe -Arguments $arguments -WorkingDirectory $Context.Paths.SnowyMergerDir -Dispatcher $Context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onProcessError
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
        $ui.StatusLine.Text = '正在停止 SnowyMerger 及其子进程...'
        $pidToStop = $state.Process.Process.Id

        try {
            $killerInfo = New-Object Diagnostics.ProcessStartInfo
            $killerInfo.FileName = 'taskkill.exe'
            $killerInfo.Arguments = "/PID $pidToStop /T /F"
            $killerInfo.UseShellExecute = $false
            $killerInfo.CreateNoWindow = $true
            $killer = [Diagnostics.Process]::Start($killerInfo)
            if ($killer) {
                [void]$killer.WaitForExit(5000)
                $killer.Dispose()
            }
            if (-not $state.Process.Process.HasExited) {
                $state.Process.Process.Kill()
            }
        } catch {
            $state.CancelRequested = $false
            throw "停止任务失败: $($_.Exception.Message)"
        }
    }.GetNewClosure()

    Register-CkButtonAction -Button $ui.DotNetButton -Action $openDotNetAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.AutoDetectGtaButton -Action $autoDetectGtaAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseGtaButton -Action $chooseGtaAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseInputButton -Action $chooseInputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseOutputButton -Action $chooseOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenOutputButton -Action $openOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenReportButton -Action $openReportAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StartButton -Action $startAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StopButton -Action $stopAction -OnError $showPageError

    & $updateEnvironmentAction
    return [pscustomobject]@{
        Id = 'snowy-merger'
        Title = '地图冲突合并'
        Icon = '≋'
        Root = $root
        Activate = $updateEnvironmentAction
    }
}
