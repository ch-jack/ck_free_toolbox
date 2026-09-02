function New-CkVjmiDevToolsPage {
    param([Parameter(Mandatory)]$Context)

    Add-Type -AssemblyName System.Net.Http

    $state = [pscustomobject]@{
        LastPid = 0
        ProbeAttempts = 0
    }

    $xaml = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
              xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
              VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"
              Padding="22,16,28,32">
  <StackPanel>
    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="18" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,14">
          <StackPanel Orientation="Horizontal">
            <Border Width="4" Height="22" CornerRadius="3" Background="#72B7F2" Margin="0,0,10,0"/>
            <StackPanel>
              <TextBlock Text="FiveM NUI 调试" FontSize="21" FontWeight="Bold"/>
              <TextBlock Text="Arya FiveM Tool · CDP 流量监控 · NUI 检查 · JavaScript 调试" Foreground="#AAB2BE" FontSize="12" Margin="0,4,0,0"/>
            </StackPanel>
          </StackPanel>
          <TextBlock x:Name="EnvironmentStatus" Text="检测中" HorizontalAlignment="Right" VerticalAlignment="Center" Foreground="#F4B860" FontSize="14" FontWeight="SemiBold"/>
        </Grid>

        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Border Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="0,0,6,0">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Ellipse x:Name="ComponentDot" Width="9" Height="9" Fill="#F4B860" VerticalAlignment="Center"/><StackPanel Grid.Column="1"><TextBlock Text="自包含组件" FontWeight="SemiBold"/><TextBlock x:Name="ComponentText" Text="检测中" Foreground="#AAB2BE" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel></Grid>
          </Border>
          <Border Grid.Column="1" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="6,0">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Ellipse x:Name="FiveMDot" Width="9" Height="9" Fill="#F4B860" VerticalAlignment="Center"/><StackPanel Grid.Column="1"><TextBlock Text="FiveM DevTools" FontWeight="SemiBold"/><TextBlock x:Name="FiveMText" Text="检测中" Foreground="#AAB2BE" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel></Grid>
          </Border>
          <Border Grid.Column="2" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="6,0,0,0">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Ellipse x:Name="AppDot" Width="9" Height="9" Fill="#F4B860" VerticalAlignment="Center"/><StackPanel Grid.Column="1"><TextBlock Text="Arya 本地界面" FontWeight="SemiBold"/><TextBlock x:Name="AppText" Text="检测中" Foreground="#AAB2BE" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel></Grid>
          </Border>
        </Grid>
      </StackPanel>
    </Border>

    <Border Background="#101A16" BorderBrush="#1E4D3C" BorderThickness="1" CornerRadius="8" Padding="17" Margin="0,0,0,14">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="32"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
        <TextBlock Text="i" Foreground="#54E0A9" FontSize="21" FontWeight="Bold" VerticalAlignment="Top"/>
        <StackPanel Grid.Column="1">
          <TextBlock Text="运行方式" Foreground="#9DE0C6" FontSize="14" FontWeight="SemiBold"/>
          <TextBlock Text="组件是独立 Windows x64 程序；优先使用 WebView2 窗口，失败时自动打开本机浏览器。工具箱不安装 Python，也不把组件二进制打进 CK 发布包。" Foreground="#B8C9C1" FontSize="12" TextWrapping="Wrap" LineHeight="20" Margin="0,5,0,0"/>
          <TextBlock Text="先启动 FiveM 并进入服务器，再启动 Arya。它只连接本机 localhost:13172，不安装 DLL 或外部 Hook。" Foreground="#8FC7F3" FontSize="12" TextWrapping="Wrap" LineHeight="20" Margin="0,5,0,0"/>
        </StackPanel>
      </Grid>
    </Border>

    <Border Background="#211715" BorderBrush="#633B34" BorderThickness="1" CornerRadius="8" Padding="17" Margin="0,0,0,14">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="32"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
        <TextBlock Text="!" Foreground="#F4B860" FontSize="21" FontWeight="Bold" VerticalAlignment="Top"/>
        <StackPanel Grid.Column="1">
          <TextBlock Text="仅限自有或明确授权的服务器" Foreground="#FFD39B" FontSize="14" FontWeight="SemiBold"/>
          <TextBlock Text="JavaScript 执行、URL 屏蔽以及 vRP 批量传送、封禁、监禁、消息和转账会影响实时界面、玩家或服务器数据。启动前会再次确认，vRP 批量动作在 Arya 内还会单独确认。" Foreground="#DAB7A7" FontSize="12" TextWrapping="Wrap" LineHeight="20" Margin="0,5,0,0"/>
        </StackPanel>
      </Grid>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="18">
      <StackPanel>
        <TextBlock Text="启动与诊断" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/><ColumnDefinition Width="150"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions>
          <Button x:Name="LaunchButton" AutomationProperties.AutomationId="VjmiDevTools.LaunchButton" Content="启动 Arya 工具" Height="44" Margin="0,0,8,0" Background="#12382D" Foreground="#9DE0C6" FontWeight="Bold"/>
          <Button x:Name="RefreshButton" AutomationProperties.AutomationId="VjmiDevTools.RefreshButton" Grid.Column="1" Content="重新检测" Height="44" Margin="8,0"/>
          <Button x:Name="OpenComponentButton" AutomationProperties.AutomationId="VjmiDevTools.OpenComponentButton" Grid.Column="2" Content="打开组件目录" Height="44" Margin="8,0"/>
          <Button x:Name="OpenDataButton" AutomationProperties.AutomationId="VjmiDevTools.OpenDataButton" Grid.Column="3" Content="打开数据与日志" Height="44" Margin="8,0,0,0"/>
        </Grid>
        <ProgressBar x:Name="ProbeProgress" Height="7" Minimum="0" Maximum="10" Value="0" Visibility="Collapsed" Margin="0,13,0,0"/>
        <TextBlock x:Name="StatusLine" Text="等待检测组件和本机 FiveM 状态。" Foreground="#8B9099" FontSize="13" TextWrapping="Wrap" Margin="0,10,0,0"/>
      </StackPanel>
    </Border>
  </StackPanel>
</ScrollViewer>
"@

    $root = Import-CkXaml $xaml
    $ui = Get-CkNamedControls -Root $root -Names @(
        'EnvironmentStatus','ComponentDot','ComponentText','FiveMDot','FiveMText','AppDot','AppText',
        'LaunchButton','RefreshButton','OpenComponentButton','OpenDataButton','ProbeProgress','StatusLine'
    )

    function Invoke-VjmiJsonProbe {
        param([Parameter(Mandatory)][string]$Url, [int]$TimeoutMilliseconds = 650)

        $client = New-Object Net.Http.HttpClient
        $client.Timeout = [TimeSpan]::FromMilliseconds($TimeoutMilliseconds)
        try {
            $response = $client.GetAsync($Url).GetAwaiter().GetResult()
            try {
                $statusCode = [int]$response.StatusCode
                if ($statusCode -lt 200 -or $statusCode -ge 300) { return $null }
                $json = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                return ($json | ConvertFrom-Json)
            } finally {
                $response.Dispose()
            }
        } catch {
            return $null
        } finally {
            $client.Dispose()
        }
    }

    $jsonProbeAction = (Get-Command Invoke-VjmiJsonProbe).ScriptBlock.GetNewClosure()

    function Get-VjmiRuntimeState {
        $exe = [string]$Context.Paths.VjmiDevToolsExe
        $versionPath = Join-Path ([string]$Context.Paths.VjmiDevToolsDir) 'VERSION'
        $manifestPath = Join-Path ([string]$Context.Paths.VjmiDevToolsDir) 'component-manifest.json'
        $componentOk = (Test-Path -LiteralPath $exe -PathType Leaf) -and
            (Test-Path -LiteralPath $versionPath -PathType Leaf) -and
            (Test-Path -LiteralPath $manifestPath -PathType Leaf)
        $version = ''
        if (Test-Path -LiteralPath $versionPath -PathType Leaf) {
            try { $version = (Get-Content -LiteralPath $versionPath -Raw -Encoding UTF8).Trim() } catch { $version = '' }
        }

        $appInfo = & $jsonProbeAction -Url 'http://127.0.0.1:5000/health'
        $appRunning = [bool]($appInfo -and [string]$appInfo.appId -ceq 'arya-fivem-tool')
        $fivem = & $jsonProbeAction -Url 'http://localhost:13172/json'
        $fivemTargets = if ($null -eq $fivem) { 0 } else { @($fivem).Count }

        return [pscustomobject]@{
            ComponentOk = [bool]$componentOk
            Version = [string]$version
            AppRunning = $appRunning
            AppVersion = $(if ($appRunning) { [string]$appInfo.version } else { '' })
            FiveMReady = ($fivemTargets -gt 0)
            FiveMTargets = $fivemTargets
        }
    }

    $getRuntimeStateAction = (Get-Command Get-VjmiRuntimeState).ScriptBlock.GetNewClosure()

    function Update-VjmiEnvironment {
        $snapshot = & $getRuntimeStateAction
        Set-CkStatusDot $ui.ComponentDot $snapshot.ComponentOk
        Set-CkStatusDot $ui.FiveMDot $snapshot.FiveMReady
        Set-CkStatusDot $ui.AppDot $snapshot.AppRunning

        $ui.ComponentText.Text = if ($snapshot.ComponentOk) {
            if ($snapshot.Version) { "已安装 v$($snapshot.Version)" } else { '已安装' }
        } else { '请在顶部安装组件' }
        $ui.ComponentText.ToolTip = [string]$Context.Paths.VjmiDevToolsDir
        $ui.FiveMText.Text = if ($snapshot.FiveMReady) { "已发现 $($snapshot.FiveMTargets) 个调试目标" } else { '等待 localhost:13172' }
        $ui.AppText.Text = if ($snapshot.AppRunning) { "运行中 v$($snapshot.AppVersion)" } else { '当前未运行' }
        $ui.LaunchButton.IsEnabled = $snapshot.ComponentOk
        $ui.OpenComponentButton.IsEnabled = $snapshot.ComponentOk
        $ui.LaunchButton.Content = if ($snapshot.AppRunning) { 'Arya 已在运行' } else { '启动 Arya 工具' }

        if (-not $snapshot.ComponentOk) {
            $ui.EnvironmentStatus.Text = '组件未安装'
            $ui.StatusLine.Text = '点击页面顶部“安装组件”，工具箱会下载并校验最新稳定 Release。'
        } elseif ($snapshot.AppRunning) {
            $ui.EnvironmentStatus.Text = 'Arya 运行中'
            $ui.StatusLine.Text = if ($snapshot.FiveMReady) { 'Arya 与 FiveM DevTools 均已就绪。' } else { 'Arya 已启动；进入 FiveM 服务器后会自动连接。' }
        } elseif ($snapshot.FiveMReady) {
            $ui.EnvironmentStatus.Text = '可以启动'
            $ui.StatusLine.Text = 'FiveM DevTools 已就绪，点击“启动 Arya 工具”。'
        } else {
            $ui.EnvironmentStatus.Text = '等待 FiveM'
            $ui.StatusLine.Text = '组件已就绪；可先启动 FiveM 并进入服务器，也可以直接打开 Arya 等待连接。'
        }
        return $snapshot
    }

    $updateEnvironmentAction = (Get-Command Update-VjmiEnvironment).ScriptBlock.GetNewClosure()
    $probeTimer = New-Object System.Windows.Threading.DispatcherTimer
    $probeTimer.Interval = [TimeSpan]::FromMilliseconds(750)
    $probeTimer.Add_Tick({
        $state.ProbeAttempts++
        $ui.ProbeProgress.Value = $state.ProbeAttempts
        $snapshot = & $updateEnvironmentAction
        if ($snapshot.AppRunning -or $state.ProbeAttempts -ge 10) {
            $probeTimer.Stop()
            $ui.ProbeProgress.Visibility = 'Collapsed'
        }
    }.GetNewClosure())

    $launchAction = {
        $snapshot = & $updateEnvironmentAction
        if (-not $snapshot.ComponentOk) { throw 'Arya 组件未安装或不完整，请先点击顶部“安装组件”。' }
        if ($snapshot.AppRunning) {
            [System.Windows.MessageBox]::Show(
                'Arya FiveM Tool 已经在本机运行。请切换到现有窗口。',
                'CK免费工具箱',
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            ) | Out-Null
            return
        }

        $confirmation = [System.Windows.MessageBox]::Show(
            "仅限在您自有或明确获授权的 FiveM 服务器使用。`n`nJavaScript 执行、URL 屏蔽和 vRP 批量动作可能影响玩家或服务器数据。确认继续启动吗？",
            '启动 Arya FiveM Tool',
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )
        if ($confirmation -ne [System.Windows.MessageBoxResult]::Yes) { return }

        $startInfo = New-Object Diagnostics.ProcessStartInfo
        $startInfo.FileName = [string]$Context.Paths.VjmiDevToolsExe
        $startInfo.WorkingDirectory = [string]$Context.Paths.VjmiDevToolsDir
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
        $process = [Diagnostics.Process]::Start($startInfo)
        if (-not $process) { throw 'Arya 进程未能启动。' }
        $state.LastPid = $process.Id
        $process.Dispose()

        $state.ProbeAttempts = 0
        $ui.ProbeProgress.Value = 0
        $ui.ProbeProgress.Visibility = 'Visible'
        $ui.StatusLine.Text = "Arya 已启动（PID $($state.LastPid)），正在等待本地界面就绪。"
        $probeTimer.Start()
    }.GetNewClosure()

    $openComponentAction = {
        if (-not (Test-Path -LiteralPath ([string]$Context.Paths.VjmiDevToolsDir) -PathType Container)) {
            throw '组件目录不存在，请先安装组件。'
        }
        Start-Process -FilePath explorer.exe -ArgumentList @([string]$Context.Paths.VjmiDevToolsDir)
    }.GetNewClosure()

    $openDataAction = {
        $dataRoot = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'AryaJSTool'
        if (-not (Test-Path -LiteralPath $dataRoot -PathType Container)) {
            [IO.Directory]::CreateDirectory($dataRoot) | Out-Null
        }
        Start-Process -FilePath explorer.exe -ArgumentList @($dataRoot)
    }.GetNewClosure()

    Register-CkButtonAction -Button $ui.LaunchButton -Action $launchAction
    Register-CkButtonAction -Button $ui.RefreshButton -Action $updateEnvironmentAction
    Register-CkButtonAction -Button $ui.OpenComponentButton -Action $openComponentAction
    Register-CkButtonAction -Button $ui.OpenDataButton -Action $openDataAction

    [void](& $updateEnvironmentAction)
    return [pscustomobject]@{
        Id = 'vjmidevtools'
        Title = 'FiveM NUI 调试'
        Icon = '⌘'
        Root = $root
        Activate = $updateEnvironmentAction
    }
}
