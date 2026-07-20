function New-CkServerDumpPage {
    param([Parameter(Mandatory)]$Context)

    $reportRoot = Join-Path (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CKFreeToolbox') 'server-dump-reports'
    $state = [pscustomobject]@{
        Process = $null
        CancelRequested = $false
        ReportRoot = $reportRoot
        ReportPath = ''
        StartedAt = $null
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
            <StackPanel>
              <TextBlock Text="服务器 Dump" FontSize="21" FontWeight="Bold"/>
              <TextBlock Text="支持服务器 Dump 和 FXAP 解密，不含模型修复。" Foreground="#F4B860" FontSize="12" Margin="0,4,0,0"/>
            </StackPanel>
          </StackPanel>
          <TextBlock x:Name="EnvironmentStatus" AutomationProperties.AutomationId="ServerDump.EnvironmentStatus" Text="检测中" HorizontalAlignment="Right" VerticalAlignment="Center" Foreground="#F4B860" FontSize="14" FontWeight="SemiBold"/>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Border Grid.Column="0" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="0,0,5,0">
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/><ColumnDefinition Width="94"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="PythonDot" Width="9" Height="9" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1">
                <TextBlock Text="Python" FontSize="14" FontWeight="SemiBold"/>
                <TextBlock x:Name="PythonText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/>
              </StackPanel>
              <StackPanel Grid.Column="2" Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="PythonDownloadButton" AutomationProperties.AutomationId="ServerDump.PythonDownloadButton" Content="官网" Width="42" Height="27" Margin="0,0,5,0" Foreground="#58A6FF" Visibility="Collapsed" ToolTip="打开 Python 官方 Windows 下载页面"/>
                <Button x:Name="PythonBrowseButton" AutomationProperties.AutomationId="ServerDump.PythonBrowseButton" Content="选择" Width="42" Height="27" ToolTip="选择 Python 安装目录中的 python.exe"/>
              </StackPanel>
            </Grid>
          </Border>
          <Border Grid.Column="1" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="5,0">
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="DepsDot" Width="9" Height="9" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1">
                <TextBlock Text="Python 依赖" FontSize="14" FontWeight="SemiBold"/>
                <TextBlock x:Name="DepsText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/>
              </StackPanel>
            </Grid>
          </Border>
          <Border Grid.Column="2" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="5,0,0,0">
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="ComponentDot" Width="9" Height="9" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1">
                <TextBlock Text="Dump 组件" FontSize="14" FontWeight="SemiBold"/>
                <TextBlock x:Name="ComponentText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/>
              </StackPanel>
            </Grid>
          </Border>
        </Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="输入与输出" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid Margin="0,0,0,10">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="104"/></Grid.ColumnDefinitions>
          <StackPanel>
            <TextBlock Text="cfx.re link 或 IP:端口" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/>
            <TextBox x:Name="TargetBox" AutomationProperties.AutomationId="ServerDump.TargetBox" Height="36"/>
          </StackPanel>
          <Button x:Name="PasteExampleButton" AutomationProperties.AutomationId="ServerDump.PasteExampleButton" Grid.Column="1" Content="示例格式" Height="36" Margin="7,22,0,0" ToolTip="在日志中显示支持的输入格式"/>
        </Grid>
        <Grid Margin="0,0,0,10">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="88"/><ColumnDefinition Width="88"/></Grid.ColumnDefinitions>
          <StackPanel>
            <TextBlock Text="输出目录" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/>
            <TextBox x:Name="OutputBox" AutomationProperties.AutomationId="ServerDump.OutputBox" Height="36"/>
          </StackPanel>
          <Button x:Name="ChooseOutputButton" AutomationProperties.AutomationId="ServerDump.ChooseOutputButton" Grid.Column="1" Content="选择目录" Height="36" Margin="7,22,0,0" Background="#173055" Foreground="#58A6FF"/>
          <Button x:Name="OpenOutputButton" AutomationProperties.AutomationId="ServerDump.OpenOutputButton" Grid.Column="2" Content="打开输出" Height="36" Margin="7,22,0,0"/>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="220"/></Grid.ColumnDefinitions>
          <StackPanel>
            <TextBlock Text="资源选择" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/>
            <TextBox x:Name="ResourcesBox" AutomationProperties.AutomationId="ServerDump.ResourcesBox" Height="36" Text="all" ToolTip="输入 all，或填逗号分隔的资源序号/资源名"/>
          </StackPanel>
          <StackPanel Grid.Column="1" Orientation="Horizontal" Margin="10,23,0,0">
            <CheckBox x:Name="KeepTempBox" AutomationProperties.AutomationId="ServerDump.KeepTempBox" Content="保留临时目录"/>
          </StackPanel>
        </Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12">
          <TextBlock Text="执行" FontSize="18" FontWeight="Bold"/>
          <TextBlock Text="默认 token_choice=1，自动扫描 FiveM 进程 token" HorizontalAlignment="Right" Foreground="#686E78" FontSize="12" VerticalAlignment="Center"/>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions>
          <Button x:Name="StartButton" AutomationProperties.AutomationId="ServerDump.StartButton" Content="开始服务器 Dump" Height="44" Margin="0,0,7,0" Background="#124834" Foreground="#54E0A9" FontSize="15" FontWeight="Bold"/>
          <Button x:Name="StopButton" AutomationProperties.AutomationId="ServerDump.StopButton" Grid.Column="1" Content="停止任务" Height="44" Margin="7,0,0,0" Foreground="#F28B94" IsEnabled="False"/>
        </Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12">
          <TextBlock Text="任务结果" FontSize="18" FontWeight="Bold"/>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
            <TextBlock x:Name="ResultStatus" AutomationProperties.AutomationId="ServerDump.ResultStatus" Text="等待任务" Foreground="#777B83" FontSize="13" VerticalAlignment="Center" Margin="0,0,10,0"/>
            <Button x:Name="OpenReportButton" AutomationProperties.AutomationId="ServerDump.OpenReportButton" Content="打开本次报告" Height="28" Margin="0,0,8,0" IsEnabled="False"/>
            <Button x:Name="OpenReportHistoryButton" AutomationProperties.AutomationId="ServerDump.OpenReportHistoryButton" Content="报告历史" Height="28"/>
          </StackPanel>
        </Grid>
        <UniformGrid Columns="6" Margin="0,0,0,12">
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="0,0,4,0"><StackPanel><TextBlock Text="资源" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="ResourceCount" Text="0" FontSize="19" FontWeight="Bold"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="下载文件" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="DownloadedCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#58A6FF"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="RPF 解包" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="RpfCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#72B7F2"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="FXAP 解密" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="DecryptedCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#31D69A"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="输出文件" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="OutputFileCount" Text="0" FontSize="19" FontWeight="Bold"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0,0,0"><StackPanel><TextBlock Text="警告/错误" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="WarningErrorCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#F4B860"/></StackPanel></Border>
        </UniformGrid>
        <ProgressBar x:Name="ProgressBar" AutomationProperties.AutomationId="ServerDump.ProgressBar" Height="8" Minimum="0" Maximum="100" Value="0"/>
        <TextBlock x:Name="StatusLine" AutomationProperties.AutomationId="ServerDump.StatusLine" Text="输入目标地址后开始；请确保 FiveM 已进入目标服务器。" Foreground="#8B9099" FontSize="13" Margin="0,9,0,0"/>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16">
      <StackPanel>
        <Grid Margin="0,0,0,10">
          <TextBlock Text="任务日志" FontSize="18" FontWeight="Bold"/>
          <TextBlock Text="功能含 Dump、解密 FXAP，不含修复模型。" HorizontalAlignment="Right" Foreground="#686E78" FontSize="12" VerticalAlignment="Center"/>
        </Grid>
        <TextBox x:Name="LogBox" AutomationProperties.AutomationId="ServerDump.LogBox" MinHeight="210" MaxHeight="420" AcceptsReturn="True" TextWrapping="NoWrap" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" IsReadOnly="True" Text="等待任务输出..."/>
      </StackPanel>
    </Border>
  </StackPanel>
</ScrollViewer>
"@

    $root = Import-CkXaml $xaml
    $ui = Get-CkNamedControls -Root $root -Names @(
        'EnvironmentStatus','PythonDot','PythonText','PythonDownloadButton','PythonBrowseButton','DepsDot','DepsText','ComponentDot','ComponentText',
        'TargetBox','PasteExampleButton','OutputBox','ChooseOutputButton','OpenOutputButton','ResourcesBox','KeepTempBox',
        'StartButton','StopButton','ResultStatus','OpenReportButton','OpenReportHistoryButton','ResourceCount','DownloadedCount',
        'RpfCount','DecryptedCount','OutputFileCount','WarningErrorCount','ProgressBar','StatusLine','LogBox'
    )

    $ui.OutputBox.Text = [string]$Context.Paths.DefaultServerDumpOutput

    function Get-ServerDumpPythonInfo {
        $environment = Get-CkToolboxEnvironment -Context $Context
        $blender = if ($environment.Blender.Ok) { $environment.Blender.Path } else { '' }
        $settings = Get-CkDependencySettings
        return Get-CkPythonInfo -RuntimeRoot $Context.Paths.RuntimeRoot -BlenderExe $blender -ConfiguredPath ([string]$settings.PythonPath)
    }

    function Test-ServerDumpPythonPackages {
        param([string]$Python)

        if (-not $Python -or -not (Test-Path -LiteralPath $Python -PathType Leaf)) {
            return [pscustomobject]@{ Ok = $false; Label = '未检测'; Reason = 'Python 不存在。' }
        }

        $process = $null
        try {
            $psi = New-Object Diagnostics.ProcessStartInfo
            $psi.FileName = $Python
            $psi.Arguments = '-c "import psutil, requests; from Crypto.Cipher import AES, ChaCha20; print(''OK'')"'
            $psi.WorkingDirectory = $Context.Paths.DumpToolDir
            $psi.UseShellExecute = $false
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.CreateNoWindow = $true
            try {
                $psi.StandardOutputEncoding = [Text.Encoding]::UTF8
                $psi.StandardErrorEncoding = [Text.Encoding]::UTF8
            } catch { }

            $process = New-Object Diagnostics.Process
            $process.StartInfo = $psi
            if (-not $process.Start()) { throw '依赖检测进程未启动。' }
            if (-not $process.WaitForExit(8000)) {
                try { $process.Kill() } catch { }
                return [pscustomobject]@{ Ok = $false; Label = '检测超时'; Reason = 'Python 依赖检测超过 8 秒。' }
            }
            $stderr = $process.StandardError.ReadToEnd().Trim()
            if ($process.ExitCode -ne 0) {
                $detail = if ($stderr) { $stderr } else { "退出码 $($process.ExitCode)" }
                return [pscustomobject]@{ Ok = $false; Label = '缺少依赖'; Reason = "请在 dump-tool 目录执行 pip install -r requirements.txt。$detail" }
            }
            return [pscustomobject]@{ Ok = $true; Label = 'psutil / requests / Crypto 已就绪'; Reason = '' }
        } catch {
            return [pscustomobject]@{ Ok = $false; Label = '检测失败'; Reason = $_.Exception.Message }
        } finally {
            if ($process) { $process.Dispose() }
        }
    }

    function Get-ServerDumpPython {
        $info = & $getPythonInfoAction
        if (-not $info.Ok) { throw [string]$info.Reason }
        return [string]$info.Path
    }

    function Update-ServerDumpEnvironment {
        $pythonInfo = & $getPythonInfoAction
        $pythonOk = [bool]$pythonInfo.Ok
        $depsInfo = if ($pythonOk) { & $testPackagesAction ([string]$pythonInfo.Path) } else { [pscustomobject]@{ Ok = $false; Label = '等待 Python'; Reason = [string]$pythonInfo.Reason } }
        $scriptOk = Test-Path -LiteralPath $Context.Paths.DumpToolScript -PathType Leaf
        $requirementsOk = Test-Path -LiteralPath (Join-Path $Context.Paths.DumpToolDir 'requirements.txt') -PathType Leaf
        $unpackerOk = Test-Path -LiteralPath (Join-Path $Context.Paths.DumpToolDir 'Bin\Unpacker.exe') -PathType Leaf
        $unluacOk = Test-Path -LiteralPath (Join-Path $Context.Paths.DumpToolDir 'Tools\Decompile\unluac54.jar') -PathType Leaf
        $fixerOk = Test-Path -LiteralPath (Join-Path $Context.Paths.DumpToolDir 'FIXER\FivemDecryptFixer.exe') -PathType Leaf
        $componentOk = $scriptOk -and $requirementsOk -and $unpackerOk -and $unluacOk -and $fixerOk

        Set-CkStatusDot $ui.PythonDot $pythonOk
        Set-CkStatusDot $ui.DepsDot ([bool]$depsInfo.Ok)
        Set-CkStatusDot $ui.ComponentDot $componentOk

        $ui.PythonText.Text = [string]$pythonInfo.Label
        $ui.PythonText.ToolTip = if ($pythonOk) { [string]$pythonInfo.Path } else { [string]$pythonInfo.Reason }
        $ui.PythonDownloadButton.Visibility = if ($pythonOk) { 'Collapsed' } else { 'Visible' }
        $ui.PythonBrowseButton.Content = if ($pythonOk) { '更改' } else { '选择' }
        $ui.DepsText.Text = [string]$depsInfo.Label
        $ui.DepsText.ToolTip = [string]$depsInfo.Reason

        if ($componentOk) {
            $ui.ComponentText.Text = 'Dump 与 FXAP 解密组件已就绪'
        } elseif (-not $scriptOk) {
            $ui.ComponentText.Text = '缺少 auto.py，请安装组件'
        } elseif (-not $requirementsOk) {
            $ui.ComponentText.Text = '缺少 requirements.txt'
        } elseif (-not $unpackerOk) {
            $ui.ComponentText.Text = '缺少 RPF 解包器'
        } elseif (-not $unluacOk) {
            $ui.ComponentText.Text = '缺少 unluac54.jar'
        } else {
            $ui.ComponentText.Text = '组件不完整，请重新安装'
        }

        $allOk = $pythonOk -and $depsInfo.Ok -and $componentOk
        $ui.EnvironmentStatus.Text = if ($allOk) { '运行环境就绪' } else { '请处理缺失项' }
        $ui.EnvironmentStatus.Foreground = if ($allOk) { '#31D69A' } else { '#F4B860' }
    }

    function Set-ServerDumpRunning {
        param([bool]$Running)

        foreach ($control in @($ui.TargetBox,$ui.PasteExampleButton,$ui.OutputBox,$ui.ChooseOutputButton,$ui.OpenOutputButton,$ui.ResourcesBox,$ui.KeepTempBox,$ui.PythonDownloadButton,$ui.PythonBrowseButton,$ui.StartButton)) {
            $control.IsEnabled = -not $Running
        }
        $ui.StopButton.IsEnabled = $Running
        $ui.ProgressBar.IsIndeterminate = $false
        if ($Running) {
            $ui.ProgressBar.Value = 2
            $ui.ResultStatus.Text = '正在运行'
            $ui.ResultStatus.Foreground = '#72B7F2'
            $ui.StatusLine.Text = '正在执行服务器 Dump 与 FXAP 解密，可随时停止。'
        }
    }

    function Get-ServerDumpSummaryValue {
        param($Summary, [string]$Name)
        if ($Summary -and $Summary.PSObject.Properties[$Name]) { return [int]$Summary.$Name }
        return 0
    }

    function Show-ServerDumpResult {
        param($Payload, [int]$ExitCode)

        $summary = $Payload.summary
        $resourceCount = & $getSummaryValueAction $summary 'server_resources_selected'
        if (-not $resourceCount) { $resourceCount = & $getSummaryValueAction $summary 'server_resources_total' }
        $downloaded = & $getSummaryValueAction $summary 'downloaded_files'
        $rpf = & $getSummaryValueAction $summary 'rpf_unpacked'
        $decrypted = & $getSummaryValueAction $summary 'resources_decrypted'
        $outputFiles = & $getSummaryValueAction $summary 'output_files'
        $warnings = & $getSummaryValueAction $summary 'warnings'
        $errors = & $getSummaryValueAction $summary 'errors'

        $ui.ResourceCount.Text = [string]$resourceCount
        $ui.DownloadedCount.Text = [string]$downloaded
        $ui.RpfCount.Text = [string]$rpf
        $ui.DecryptedCount.Text = [string]$decrypted
        $ui.OutputFileCount.Text = [string]$outputFiles
        $ui.WarningErrorCount.Text = [string]($warnings + $errors)
        $ui.ProgressBar.Value = if ($ExitCode -in @(0, 10)) { 100 } else { 94 }

        $reportPath = ''
        if ($Payload.PSObject.Properties['execution_report'] -and $Payload.execution_report) {
            if ($Payload.execution_report.markdown) {
                $reportPath = [string]$Payload.execution_report.markdown
            } elseif ($Payload.execution_report.json) {
                $reportPath = [string]$Payload.execution_report.json
            }
        }
        if (-not $reportPath -and $state.ReportPath) { $reportPath = [string]$state.ReportPath }
        if ($reportPath -and (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
            $state.ReportPath = [IO.Path]::GetFullPath($reportPath)
            $ui.OpenReportButton.IsEnabled = $true
        } else {
            $state.ReportPath = ''
            $ui.OpenReportButton.IsEnabled = $false
        }

        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add("状态: $($Payload.status)")
        $lines.Add("目标: $($Payload.target)")
        $lines.Add("服务器地址: $($Payload.server_address)")
        $lines.Add("输出目录: $($Payload.output)")
        $lines.Add("功能范围: 包含服务器 Dump、FXAP 解密；不含模型修复")
        if ($state.ReportPath) { $lines.Add("本次报告: $($state.ReportPath)") }
        foreach ($errorItem in @($Payload.errors)) { $lines.Add("错误: $errorItem") }
        $lines.Add('')

        foreach ($item in @($Payload.dump_resources | Select-Object -First 120)) {
            $lines.Add("[Dump/$($item.status)] $($item.name) | 下载 $($item.downloaded_files)/$($item.files_total) | RPF $($item.rpf_unpacked)")
            foreach ($warning in @($item.warnings | Select-Object -First 3)) { $lines.Add("  警告: $warning") }
            foreach ($errorText in @($item.errors | Select-Object -First 3)) { $lines.Add("  错误: $errorText") }
        }
        foreach ($item in @($Payload.decrypt_resources | Select-Object -First 120)) {
            $lines.Add("[FXAP/$($item.status)] $($item.name) | 解密 $($item.decrypted_files) | 复制 $($item.copied_files) | 失败 $($item.failed_files)")
            foreach ($warning in @($item.warnings | Select-Object -First 3)) { $lines.Add("  警告: $warning") }
            foreach ($errorText in @($item.errors | Select-Object -First 3)) { $lines.Add("  错误: $errorText") }
        }
        if (@($Payload.dump_resources).Count -gt 120 -or @($Payload.decrypt_resources).Count -gt 120) {
            $lines.Add('')
            $lines.Add('仅显示前 120 项，完整明细请打开本次报告。')
        }

        $ui.LogBox.Text = $lines -join [Environment]::NewLine
        $ui.LogBox.ScrollToHome()

        if ($Payload.status -eq 'success' -and $ExitCode -eq 0) {
            $ui.ResultStatus.Text = 'Dump 完成'
            $ui.ResultStatus.Foreground = '#31D69A'
            $ui.StatusLine.Text = "已输出 $outputFiles 个文件。"
        } elseif ($Payload.status -eq 'partial' -or $ExitCode -eq 10) {
            $ui.ResultStatus.Text = '完成，需检查'
            $ui.ResultStatus.Foreground = '#F4B860'
            $ui.StatusLine.Text = "任务完成但有 $warnings 个警告、$errors 个错误，请查看报告。"
        } else {
            $ui.ResultStatus.Text = '任务失败'
            $ui.ResultStatus.Foreground = '#EF6B73'
            $ui.StatusLine.Text = if (@($Payload.errors).Count) { [string]@($Payload.errors)[0] } else { "进程退出码: $ExitCode" }
        }
    }

    $getPythonInfoAction = (Get-Command Get-ServerDumpPythonInfo).ScriptBlock.GetNewClosure()
    $testPackagesAction = (Get-Command Test-ServerDumpPythonPackages).ScriptBlock.GetNewClosure()
    $getPythonAction = (Get-Command Get-ServerDumpPython).ScriptBlock.GetNewClosure()
    $updateEnvironmentAction = (Get-Command Update-ServerDumpEnvironment).ScriptBlock.GetNewClosure()
    $setRunningAction = (Get-Command Set-ServerDumpRunning).ScriptBlock.GetNewClosure()
    $getSummaryValueAction = (Get-Command Get-ServerDumpSummaryValue).ScriptBlock.GetNewClosure()
    $showResultAction = (Get-Command Show-ServerDumpResult).ScriptBlock.GetNewClosure()

    $showPageError = {
        param([string]$message)
        $ui.ResultStatus.Text = '操作失败'
        $ui.ResultStatus.Foreground = '#EF6B73'
        $ui.StatusLine.Text = $message
        Add-CkLogLine -TextBox $ui.LogBox -Line "[工具箱] $message"
        [System.Windows.MessageBox]::Show($message, 'CK免费工具箱 - 服务器 Dump') | Out-Null
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

    $chooseOutputAction = {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = '选择服务器 Dump 输出目录'
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
        if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { throw '本次报告不存在，请先完成一次服务器 Dump。' }
        Start-Process -FilePath notepad.exe -ArgumentList @("`"$path`"") -ErrorAction Stop
    }.GetNewClosure()

    $openReportHistoryAction = {
        $path = [string]$state.ReportRoot
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            New-Item -ItemType Directory -Force -Path $path | Out-Null
        }
        Start-Process -FilePath explorer.exe -ArgumentList @($path)
    }.GetNewClosure()

    $showExampleAction = {
        $ui.LogBox.Text = "支持输入示例：`r`nhttps://cfx.re/join/xxxx`r`n1.2.3.4:30120`r`n`r`n功能含 Dump、解密 FXAP，不含修复模型。"
    }.GetNewClosure()

    function Start-ServerDump {
        if ($state.Process -and -not $state.Process.Process.HasExited) { throw '已有服务器 Dump 任务正在运行。' }
        if (-not (Test-Path -LiteralPath $Context.Paths.DumpToolScript -PathType Leaf)) { throw '服务器 Dump 组件未安装，请先点击顶部“安装组件”。' }
        foreach ($relative in @('requirements.txt','Bin\Unpacker.exe','Tools\Decompile\unluac54.jar','FIXER\FivemDecryptFixer.exe')) {
            $required = Join-Path $Context.Paths.DumpToolDir $relative
            if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "服务器 Dump 组件不完整，缺少: $relative" }
        }

        $target = $ui.TargetBox.Text.Trim()
        if (-not $target) { throw '请输入 cfx.re link 或 IP:端口。' }
        if ($target -notmatch '^(https?://)?(cfx\.re/join/[A-Za-z0-9]+|servers\.fivem\.net/servers/detail/[A-Za-z0-9]+|\d{1,3}(\.\d{1,3}){3}:\d{1,5})/?$') {
            throw '目标格式不正确，请输入 cfx.re link 或 IP:端口。'
        }

        $outputPath = $ui.OutputBox.Text.Trim()
        if (-not $outputPath) { throw '请选择输出目录。' }
        $outputPath = [IO.Path]::GetFullPath($outputPath).TrimEnd('\')
        $driveRoot = [IO.Path]::GetPathRoot($outputPath).TrimEnd('\')
        if ($outputPath.Equals($driveRoot, [StringComparison]::OrdinalIgnoreCase)) { throw '不能直接输出到磁盘根目录。' }
        New-Item -ItemType Directory -Force -Path $outputPath | Out-Null

        $python = & $getPythonAction
        $deps = & $testPackagesAction $python
        if (-not $deps.Ok) { throw [string]$deps.Reason }

        $resources = $ui.ResourcesBox.Text.Trim()
        if (-not $resources) { $resources = 'all' }

        $runDir = Join-Path $state.ReportRoot ((Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 6))
        New-Item -ItemType Directory -Force -Path $runDir | Out-Null
        $reportPath = Join-Path $runDir 'report.json'

        $args = @(
            '-u', $Context.Paths.DumpToolScript,
            $target,
            '--token-choice', '1',
            '--resources', $resources,
            '--output', $outputPath,
            '--report', $reportPath,
            '--non-interactive'
        )
        if ($ui.KeepTempBox.IsChecked) { $args += '--keep-temp' }

        $state.CancelRequested = $false
        $state.ReportPath = ''
        $state.StartedAt = Get-Date
        $ui.OpenReportButton.IsEnabled = $false
        foreach ($counter in @($ui.ResourceCount,$ui.DownloadedCount,$ui.RpfCount,$ui.DecryptedCount,$ui.OutputFileCount,$ui.WarningErrorCount)) { $counter.Text = '0' }
        $ui.LogBox.Text = "开始服务器 Dump...`r`n目标: $target`r`n输出: $outputPath`r`n功能: Dump + FXAP 解密，不含模型修复。"
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
                try {
                    $progress = $line.Substring(12) | ConvertFrom-Json
                    $callbackUi.ProgressBar.Value = [Math]::Max(0, [Math]::Min(100, [int]$progress.percent))
                    $callbackUi.StatusLine.Text = [string]$progress.message
                    if ($progress.stage) { $callbackUi.ResultStatus.Text = [string]$progress.stage }
                } catch { }
                return
            }
            if ($line -and $line.StartsWith('CK_REPORT ', [StringComparison]::Ordinal)) {
                try {
                    $reportInfo = $line.Substring(10) | ConvertFrom-Json
                    $candidate = if ($reportInfo.markdown) { [string]$reportInfo.markdown } else { [string]$reportInfo.json }
                    if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
                        $callbackState.ReportPath = [IO.Path]::GetFullPath($candidate)
                        $callbackUi.OpenReportButton.IsEnabled = $true
                    }
                } catch { }
                return
            }
            [void]$callbackOutput.AppendLine($line)
            if ($line) { Add-CkLogLine -TextBox $callbackUi.LogBox -Line $line }
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
                $callbackUi.StatusLine.Text = "进程退出码: $exitCode；dump-tool 没有返回有效 JSON。"
                $callbackUi.LogBox.Text = if ($raw) { $raw } else { 'dump-tool 没有返回输出。' }
            }

            if ($wasCancelled) {
                $callbackUi.ProgressBar.Value = 0
                $callbackUi.ResultStatus.Text = '任务已停止'
                $callbackUi.ResultStatus.Foreground = '#F4B860'
                if ($callbackState.ReportPath) {
                    $callbackUi.StatusLine.Text = '任务已停止；已保留停止前生成的报告。'
                    Add-CkLogLine -TextBox $callbackUi.LogBox -Line "本次报告: $($callbackState.ReportPath)"
                } else {
                    $callbackUi.StatusLine.Text = '任务已停止；组件尚未生成完整报告。'
                    Add-CkLogLine -TextBox $callbackUi.LogBox -Line '[工具箱] 任务已停止，组件尚未生成完整报告。'
                }
            }
        }.GetNewClosure()

        try {
            $state.Process = Start-CkLoggedProcess -FileName $python -Arguments $args -WorkingDirectory $Context.Paths.DumpToolDir -Dispatcher $Context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onProcessError
        } catch {
            & $setRunningAction $false
            throw
        }
    }

    $startAction = (Get-Command Start-ServerDump).ScriptBlock.GetNewClosure()
    $runAction = { & $startAction }.GetNewClosure()
    $stopAction = {
        if (-not $state.Process -or $state.Process.Process.HasExited) { return }
        $state.CancelRequested = $true
        $ui.StopButton.IsEnabled = $false
        $ui.ResultStatus.Text = '正在停止'
        $ui.ResultStatus.Foreground = '#F4B860'
        $ui.StatusLine.Text = '正在停止 Python、RPF 解包和 Java 子进程...'
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

    Register-CkButtonAction -Button $ui.PythonDownloadButton -Action $openPythonDownloadAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.PythonBrowseButton -Action $selectPythonAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.PasteExampleButton -Action $showExampleAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseOutputButton -Action $chooseOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenOutputButton -Action $openOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenReportButton -Action $openReportAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenReportHistoryButton -Action $openReportHistoryAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StartButton -Action $runAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StopButton -Action $stopAction -OnError $showPageError

    & $updateEnvironmentAction
    return [pscustomobject]@{
        Id = 'server-dump'
        Title = '服务器 Dump'
        Icon = '⇣'
        Root = $root
        Activate = $updateEnvironmentAction
    }
}
