function New-CkFxapDecryptorPage {
    param([Parameter(Mandatory)]$Context)

    $reportRoot = Join-Path (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CKFreeToolbox') 'fxap-decryptor-reports'

    $state = [pscustomobject]@{
        ReportRoot = $reportRoot
        ReportPath = ''
        JsonReportPath = ''
        StartedAt = $null
        InputPath = ''
        CfxKeyProvided = $false
        NodeVersion = ''
        JavaVersion = ''
        LogBuilder = (New-Object Text.StringBuilder)
        Process = $null
        ApiHealthTask = $null
        ApiLastCheck = [datetime]::MinValue
        ApiHealthUrl = ''
        CancelRequested = $false
        Ready = $false
        NodePath = ''
        JavaPath = ''
        OutputPath = ''
        VertexFixOutputPath = ''
        VertexFixRequested = $false
        VertexFixStatus = 'disabled'
        VertexFixScanned = 0
        VertexFixRepaired = 0
        VertexFixFailed = 0
        AutoOpenRequested = $true
        ResourceTotal = 0
        CompletedResources = 0
        Decrypted = 0
        Copied = 0
        Lua = 0
        Failures = 0
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
            <Border Width="4" Height="22" CornerRadius="3" Background="#9B8CFF" Margin="0,0,10,0"/>
            <StackPanel>
              <TextBlock Text="FXAP 文件夹解密" FontSize="21" FontWeight="Bold"/>
              <TextBlock Text="选择资源目录即可自动解密；CFX key 可选，接口鉴权由 fxap_only 内部处理。" Foreground="#8B9099" FontSize="12" Margin="0,4,0,0"/>
            </StackPanel>
          </StackPanel>
          <StackPanel HorizontalAlignment="Right" VerticalAlignment="Center">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
              <Ellipse x:Name="ApiStatusDot" AutomationProperties.AutomationId="FxapDecryptor.ApiStatusDot" Width="9" Height="9" Fill="#F4B860" Margin="0,0,7,0" VerticalAlignment="Center"/>
              <TextBlock x:Name="ApiStatusText" AutomationProperties.AutomationId="FxapDecryptor.ApiStatus" Text="API 检测中" Foreground="#F4B860" FontSize="12" FontWeight="SemiBold"/>
            </StackPanel>
            <TextBlock x:Name="EnvironmentStatus" AutomationProperties.AutomationId="FxapDecryptor.EnvironmentStatus" Text="检测中" HorizontalAlignment="Right" Foreground="#F4B860" FontSize="14" FontWeight="SemiBold" Margin="0,4,0,0"/>
          </StackPanel>
        </Grid>
        <Border x:Name="ApiImpactNoticePanel" Background="#111820" BorderBrush="#2B4A68" BorderThickness="1" CornerRadius="6"
                Padding="10,7" Margin="0,0,0,12" Visibility="Collapsed">
          <Grid>
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <TextBlock Text="API 说明" Foreground="#72B7F2" FontSize="11" FontWeight="SemiBold" Margin="0,0,9,0"/>
            <TextBlock x:Name="ApiImpactNotice" AutomationProperties.AutomationId="FxapDecryptor.ApiImpactNotice" Grid.Column="1"
                       Text="API 状态不影响解密功能，仅影响无密钥解密服务。" Foreground="#8B929E" FontSize="11" TextWrapping="Wrap"/>
          </Grid>
        </Border>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Border Grid.Column="0" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="0,0,5,0">
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/><ColumnDefinition Width="94"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="NodeDot" Width="9" Height="9" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1">
                <TextBlock Text="Node.js 18+" FontSize="14" FontWeight="SemiBold"/>
                <TextBlock x:Name="NodeText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/>
              </StackPanel>
              <StackPanel Grid.Column="2" Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="NodeDownloadButton" AutomationProperties.AutomationId="FxapDecryptor.NodeDownloadButton" Content="官网" Width="42" Height="27" Margin="0,0,5,0" Foreground="#58A6FF" Visibility="Collapsed" ToolTip="打开 Node.js 官方下载页面"/>
                <Button x:Name="NodeBrowseButton" AutomationProperties.AutomationId="FxapDecryptor.NodeBrowseButton" Content="选择" Width="42" Height="27" ToolTip="选择外部 Node.js 的 node.exe"/>
              </StackPanel>
            </Grid>
          </Border>
          <Border Grid.Column="1" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="5,0">
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/><ColumnDefinition Width="94"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="JavaDot" Width="9" Height="9" Fill="#F4B860" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1">
                <TextBlock Text="Java（可选）" FontSize="14" FontWeight="SemiBold"/>
                <TextBlock x:Name="JavaText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/>
              </StackPanel>
              <StackPanel Grid.Column="2" Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="JavaDownloadButton" AutomationProperties.AutomationId="FxapDecryptor.JavaDownloadButton" Content="官网" Width="42" Height="27" Margin="0,0,5,0" Foreground="#58A6FF" Visibility="Collapsed" ToolTip="打开 Eclipse Temurin Java 17 下载页面"/>
                <Button x:Name="JavaBrowseButton" AutomationProperties.AutomationId="FxapDecryptor.JavaBrowseButton" Content="选择" Width="42" Height="27" ToolTip="选择外部 Java JDK/JRE 目录"/>
              </StackPanel>
            </Grid>
          </Border>
          <Border Grid.Column="2" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="5,0">
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/><ColumnDefinition Width="48"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="DotNet8Dot" Width="9" Height="9" Fill="#F4B860" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1">
                <TextBlock Text=".NET 8（修复）" FontSize="14" FontWeight="SemiBold"/>
                <TextBlock x:Name="DotNet8Text" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/>
              </StackPanel>
              <Button x:Name="DotNet8DownloadButton" AutomationProperties.AutomationId="FxapDecryptor.DotNet8DownloadButton" Grid.Column="2" Content="官网" Width="42" Height="27" Foreground="#58A6FF" Visibility="Collapsed" ToolTip="打开 .NET 8 Runtime 下载页面"/>
            </Grid>
          </Border>
          <Border Grid.Column="3" Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11" Margin="5,0,0,0">
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <Ellipse x:Name="ComponentDot" Width="9" Height="9" Fill="#31D69A" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1">
                <TextBlock Text="fxap_only 组件" FontSize="14" FontWeight="SemiBold"/>
                <TextBlock x:Name="ComponentText" Text="检测中" Foreground="#777B83" FontSize="11" TextTrimming="CharacterEllipsis"/>
              </StackPanel>
            </Grid>
          </Border>
        </Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="输入" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid Margin="0,0,0,11">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="98"/></Grid.ColumnDefinitions>
          <StackPanel>
            <TextBlock Text="单个 resource 或包含多个 resource 的父目录" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/>
            <TextBox x:Name="InputBox" AutomationProperties.AutomationId="FxapDecryptor.InputBox" Height="36"/>
          </StackPanel>
          <Button x:Name="ChooseFolderButton" AutomationProperties.AutomationId="FxapDecryptor.ChooseFolderButton" Grid.Column="1" Content="选择目录" Height="36" Margin="7,22,0,0" Background="#173055" Foreground="#58A6FF"/>
        </Grid>
        <Grid Margin="0,0,0,11">
          <StackPanel>
            <TextBlock Text="CFX server key（可选，不保存）" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/>
            <PasswordBox x:Name="CfxKeyBox" AutomationProperties.AutomationId="FxapDecryptor.CfxKeyBox" Height="36"/>
          </StackPanel>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="98"/></Grid.ColumnDefinitions>
          <StackPanel>
            <TextBlock Text="自动输出目录" Foreground="#8B9099" FontSize="12" Margin="0,0,0,5"/>
            <TextBox x:Name="OutputBox" AutomationProperties.AutomationId="FxapDecryptor.OutputBox" Height="36" IsReadOnly="True"/>
          </StackPanel>
          <Button x:Name="OpenOutputButton" AutomationProperties.AutomationId="FxapDecryptor.OpenOutputButton" Grid.Column="1" Content="打开输出" Height="36" Margin="7,22,0,0" IsEnabled="False"/>
        </Grid>
        <StackPanel Orientation="Horizontal" Margin="0,11,0,0">
          <CheckBox x:Name="VertexFixBox" AutomationProperties.AutomationId="FxapDecryptor.VertexFixBox" Content="解密后生成副本并自动修复顶点" Foreground="#D7DAE0" ToolTip="只处理完整解密成功的 FXAP 资源；不会覆盖原解密目录"/>
          <CheckBox x:Name="AutoOpenBox" AutomationProperties.AutomationId="FxapDecryptor.AutoOpenBox" Content="完成后自动打开文件夹" Foreground="#D7DAE0" Margin="26,0,0,0" IsChecked="True"/>
        </StackPanel>
        <Border Background="#181710" BorderBrush="#4A4020" BorderThickness="1" CornerRadius="5" Padding="9,7" Margin="0,8,0,0">
          <TextBlock Text="顶点修复不等于模型修复，不一定能 100% 修复模型，也不保证修复后的模型可以被 FiveM 加载。修复会生成完整副本，原解密输出不会被覆盖。" TextWrapping="Wrap" Foreground="#D8B968" FontSize="11"/>
        </Border>
        <Border Background="#111A24" BorderBrush="#24415F" BorderThickness="1" CornerRadius="5" Padding="9,7" Margin="0,11,0,0">
          <TextBlock Text="未填写 CFX key 或当前 resource 密钥不完整时，fxap_only 会按 resource ID 查询 grants API；客户端派生仍由 Cloudflare 完成。工具箱不提供、保存或传递接口 Bearer Token。未检测到 Java 时仍可运行，Lua 字节码会保留为 .luac。" TextWrapping="Wrap" Foreground="#8FC7F3" FontSize="11"/>
        </Border>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12">
          <TextBlock Text="执行" FontSize="18" FontWeight="Bold"/>
          <TextBlock Text="组件从 ch-jack/fxap_only 的稳定 GitHub Release 安装和更新" HorizontalAlignment="Right" Foreground="#686E78" FontSize="12" VerticalAlignment="Center"/>
        </Grid>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions>
          <Button x:Name="StartButton" AutomationProperties.AutomationId="FxapDecryptor.StartButton" Content="开始自动解密" Height="44" Margin="0,0,7,0" Background="#124834" Foreground="#54E0A9" FontSize="15" FontWeight="Bold"/>
          <Button x:Name="StopButton" AutomationProperties.AutomationId="FxapDecryptor.StopButton" Grid.Column="1" Content="停止任务" Height="44" Margin="7,0,0,0" Foreground="#F28B94" IsEnabled="False"/>
        </Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12">
          <TextBlock Text="任务结果" FontSize="18" FontWeight="Bold"/>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
            <TextBlock x:Name="ResultStatus" AutomationProperties.AutomationId="FxapDecryptor.ResultStatus" Text="等待任务" Foreground="#777B83" FontSize="13" VerticalAlignment="Center" Margin="0,0,10,0"/>
            <Button x:Name="OpenReportButton" AutomationProperties.AutomationId="FxapDecryptor.OpenReportButton" Content="打开本次报告" Height="28" Margin="0,0,8,0" IsEnabled="False"/>
            <Button x:Name="OpenReportHistoryButton" AutomationProperties.AutomationId="FxapDecryptor.OpenReportHistoryButton" Content="报告历史" Height="28"/>
          </StackPanel>
        </Grid>
        <UniformGrid Columns="5" Margin="0,0,0,12">
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="0,0,4,0"><StackPanel><TextBlock Text="资源" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="ResourceCount" Text="0" FontSize="19" FontWeight="Bold"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="已解密" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="DecryptedCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#31D69A"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="已复制" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="CopiedCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#58A6FF"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0"><StackPanel><TextBlock Text="Lua 输出" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="LuaCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#9B8CFF"/></StackPanel></Border>
          <Border Background="#15181C" CornerRadius="6" Padding="9" Margin="4,0,0,0"><StackPanel><TextBlock Text="失败" Foreground="#777B83" FontSize="11"/><TextBlock x:Name="FailureCount" Text="0" FontSize="19" FontWeight="Bold" Foreground="#F4B860"/></StackPanel></Border>
        </UniformGrid>
        <ProgressBar x:Name="ProgressBar" AutomationProperties.AutomationId="FxapDecryptor.ProgressBar" Height="8" Minimum="0" Maximum="100" Value="0"/>
        <TextBlock x:Name="StatusLine" AutomationProperties.AutomationId="FxapDecryptor.StatusLine" Text="选择包含 .fxap 的目录后开始。" Foreground="#8B9099" FontSize="13" Margin="0,9,0,0"/>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16">
      <StackPanel>
        <Grid Margin="0,0,0,10">
          <TextBlock Text="任务日志" FontSize="18" FontWeight="Bold"/>
          <TextBlock Text="不包含 decrypt-eup-stream.js 功能" HorizontalAlignment="Right" Foreground="#686E78" FontSize="12" VerticalAlignment="Center"/>
        </Grid>
        <TextBox x:Name="LogBox" AutomationProperties.AutomationId="FxapDecryptor.LogBox" MinHeight="210" MaxHeight="420" AcceptsReturn="True" TextWrapping="NoWrap" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" IsReadOnly="True" Text="等待任务输出..."/>
      </StackPanel>
    </Border>
  </StackPanel>
</ScrollViewer>
"@

    $root = Import-CkXaml $xaml
    $ui = Get-CkNamedControls -Root $root -Names @(
        'EnvironmentStatus','ApiStatusDot','ApiStatusText','ApiImpactNoticePanel','NodeDot','NodeText','NodeDownloadButton','NodeBrowseButton','JavaDot','JavaText',
        'JavaDownloadButton','JavaBrowseButton','DotNet8Dot','DotNet8Text','DotNet8DownloadButton','ComponentDot','ComponentText','InputBox','ChooseFolderButton','VertexFixBox','AutoOpenBox',
        'CfxKeyBox','OutputBox','OpenOutputButton','StartButton','StopButton','ResultStatus','OpenReportButton','OpenReportHistoryButton','ResourceCount',
        'DecryptedCount','CopiedCount','LuaCount','FailureCount','ProgressBar','StatusLine','LogBox'
    )

    function Get-FxapNodeInfo {
        return Get-CkNodeInfo -Settings (Get-CkDependencySettings)
    }

    Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
    $apiHttpClient = New-Object Net.Http.HttpClient
    $apiHttpClient.Timeout = [TimeSpan]::FromSeconds(5)
    $apiHttpClient.DefaultRequestHeaders.UserAgent.ParseAdd('CKFreeToolbox/1')
    $apiHealthTimer = New-Object System.Windows.Threading.DispatcherTimer
    $apiHealthTimer.Interval = [TimeSpan]::FromMilliseconds(200)

    function Get-FxapJavaInfo {
        return Get-CkJavaInfo -Settings (Get-CkDependencySettings)
    }

    function Get-FxapComponentInfo {
        $required = @(
            'index.js','package.json','VERSION','component-manifest.json','src\cloudflare-grants.js','src\grants-api.js',
            'src\constants.js','src\crypto.js','src\decryptor.js','src\discover.js',
            'src\java-decompiler.js','src\keymaster.js','tools\unluac54.jar','tools\unluac54.jar.sha256',
            'src\vertex-fixer.js','tools\vertex-fixer\FivemDecryptFixer.Cli.exe','tools\vertex-fixer\FivemDecryptFixer.Cli.dll',
            'tools\vertex-fixer\FivemDecryptFixer.Cli.deps.json','tools\vertex-fixer\FivemDecryptFixer.Cli.runtimeconfig.json',
            'tools\vertex-fixer\FivemDecryptFixer.dll','tools\vertex-fixer\CodeWalker.Core.dll','tools\vertex-fixer\SharpDX.dll','tools\vertex-fixer\SharpDX.Mathematics.dll'
        )
        $missing = @($required | Where-Object {
            -not (Test-Path -LiteralPath (Join-Path $Context.Paths.FxapDecryptorDir $_) -PathType Leaf)
        })
        $version = ''
        $versionPath = Join-Path $Context.Paths.FxapDecryptorDir 'VERSION'
        if (Test-Path -LiteralPath $versionPath -PathType Leaf) {
            try { $version = [IO.File]::ReadAllText($versionPath).Trim() } catch { }
        }
        $apiHealthUrl = ''
        $manifestPath = Join-Path $Context.Paths.FxapDecryptorDir 'component-manifest.json'
        if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
            try {
                $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($manifest.PSObject.Properties['apiHealthUrl']) {
                    $candidate = [string]$manifest.apiHealthUrl
                    $healthUri = [Uri]$null
                    if ([Uri]::TryCreate($candidate, [UriKind]::Absolute, [ref]$healthUri) -and
                        $healthUri.Scheme -eq [Uri]::UriSchemeHttps) {
                        $apiHealthUrl = $healthUri.AbsoluteUri
                    }
                }
            } catch { }
        }
        return [pscustomobject]@{
            Ok = ($missing.Count -eq 0)
            Missing = $missing
            Version = $version
            ApiHealthUrl = $apiHealthUrl
        }
    }

    function Set-FxapApiHealthStatus {
        param(
            [Parameter(Mandatory)][ValidateSet('unconfigured','checking','available','unavailable')][string]$Status,
            [string]$Detail = ''
        )

        switch ($Status) {
            'available' {
                $ui.ApiStatusDot.Fill = (Get-CkThemeBrush '#31D69A')
                $ui.ApiStatusText.Text = 'API 可用'
                $ui.ApiStatusText.Foreground = (Get-CkThemeBrush '#31D69A')
            }
            'unavailable' {
                $ui.ApiStatusDot.Fill = (Get-CkThemeBrush '#EF6B73')
                $ui.ApiStatusText.Text = 'API 不可用'
                $ui.ApiStatusText.Foreground = (Get-CkThemeBrush '#EF6B73')
            }
            'unconfigured' {
                $ui.ApiStatusDot.Fill = (Get-CkThemeBrush '#6E7580')
                $ui.ApiStatusText.Text = 'API 待组件'
                $ui.ApiStatusText.Foreground = (Get-CkThemeBrush '#8B929E')
            }
            default {
                $ui.ApiStatusDot.Fill = (Get-CkThemeBrush '#F4B860')
                $ui.ApiStatusText.Text = 'API 检测中'
                $ui.ApiStatusText.Foreground = (Get-CkThemeBrush '#F4B860')
            }
        }
        $ui.ApiImpactNoticePanel.Visibility = if ($Status -in @('unavailable','unconfigured')) { 'Visible' } else { 'Collapsed' }
        $tooltip = if ($state.ApiHealthUrl) { $state.ApiHealthUrl } else { '组件清单未提供 apiHealthUrl' }
        if ($Detail) { $tooltip += [Environment]::NewLine + $Detail }
        $ui.ApiStatusDot.ToolTip = $tooltip
        $ui.ApiStatusText.ToolTip = $tooltip
    }

    function Start-FxapApiHealthCheck {
        if ($state.ApiHealthTask) { return }
        if ([string]::IsNullOrWhiteSpace($state.ApiHealthUrl)) {
            & $setApiHealthStatusAction -Status unconfigured -Detail '更新 FXAP 组件后可检测 API 状态。'
            return
        }
        if (((Get-Date) - $state.ApiLastCheck).TotalSeconds -lt 30) { return }

        & $setApiHealthStatusAction -Status checking -Detail '正在检查组件 API'
        try {
            $state.ApiHealthTask = $apiHttpClient.GetAsync($state.ApiHealthUrl)
            $apiHealthTimer.Start()
        } catch {
            $state.ApiLastCheck = Get-Date
            & $setApiHealthStatusAction -Status unavailable -Detail $_.Exception.Message
        }
    }

    function Get-FxapOutputPath {
        param([string]$InputPath)

        if ([string]::IsNullOrWhiteSpace($InputPath)) { return '' }
        try {
            $fullPath = [IO.Path]::GetFullPath($InputPath).TrimEnd('\')
            $name = Split-Path -Leaf $fullPath
            $parent = Split-Path -Parent $fullPath
            if (-not $name -or -not $parent) { return '' }
            return Join-Path $parent "$($name)_decrypted"
        } catch {
            return ''
        }
    }

    function Update-FxapOutputPath {
        $state.OutputPath = & $getOutputPathAction -InputPath $ui.InputBox.Text.Trim()
        $ui.OutputBox.Text = [string]$state.OutputPath
        $ui.OpenOutputButton.IsEnabled = [bool]($state.OutputPath -and (Test-Path -LiteralPath $state.OutputPath -PathType Container))
    }

    function Update-FxapEnvironment {
        $nodeInfo = & $getNodeInfoAction
        $javaInfo = & $getJavaInfoAction
        $dotNet8Info = Get-CkDotNet8Info
        $componentInfo = & $getComponentInfoAction
        $nodeOk = [bool]$nodeInfo.Ok
        $javaOk = [bool]$javaInfo.Ok
        $dotNet8Ok = [bool]$dotNet8Info.Ok
        $componentOk = [bool]$componentInfo.Ok

        $nextApiHealthUrl = [string]$componentInfo.ApiHealthUrl
        if (-not [string]::Equals($state.ApiHealthUrl, $nextApiHealthUrl, [StringComparison]::OrdinalIgnoreCase)) {
            $state.ApiHealthUrl = $nextApiHealthUrl
            $state.ApiLastCheck = [datetime]::MinValue
        }

        $state.NodePath = if ($nodeOk) { [string]$nodeInfo.Path } else { '' }
        $state.JavaPath = if ($javaOk) { [string]$javaInfo.Path } else { '' }
        $state.Ready = $nodeOk -and $componentOk

        Set-CkStatusDot $ui.NodeDot $nodeOk
        $ui.JavaDot.Fill = if ($javaOk) { (Get-CkThemeBrush '#31D69A') } else { (Get-CkThemeBrush '#F4B860') }
        Set-CkStatusDot $ui.ComponentDot $componentOk
        $ui.NodeText.Text = [string]$nodeInfo.Label
        $ui.NodeText.ToolTip = if ($nodeOk) { [string]$nodeInfo.Path } else { [string]$nodeInfo.Reason }
        $ui.NodeDownloadButton.Visibility = if ($nodeOk) { 'Collapsed' } else { 'Visible' }
        $ui.NodeBrowseButton.Content = if ($nodeOk) { '更改' } else { '选择' }
        $ui.JavaText.Text = if ($javaOk) { [string]$javaInfo.Label } else { '未检测到，将保留 .luac' }
        $ui.JavaText.ToolTip = if ($javaOk) { "$($javaInfo.Version)$([Environment]::NewLine)$($javaInfo.Path)" } else { [string]$javaInfo.Reason }
        $ui.JavaDownloadButton.Visibility = if ($javaOk) { 'Collapsed' } else { 'Visible' }
        $ui.JavaBrowseButton.Content = if ($javaOk) { '更改' } else { '选择' }
        $ui.DotNet8Dot.Fill = if ($dotNet8Ok) { (Get-CkThemeBrush '#31D69A') } else { (Get-CkThemeBrush '#F4B860') }
        $ui.DotNet8Text.Text = [string]$dotNet8Info.Label
        $ui.DotNet8Text.ToolTip = if ($dotNet8Ok) { [string]$dotNet8Info.Path } else { '只有勾选自动修复顶点时才需要 .NET 8 Runtime。' }
        $ui.DotNet8DownloadButton.Visibility = if ($dotNet8Ok) { 'Collapsed' } else { 'Visible' }
        $ui.ComponentText.Text = if ($componentOk) {
            if ($componentInfo.Version) { "已就绪 · $($componentInfo.Version)" } else { '已就绪' }
        } else {
            '请在顶部安装组件'
        }
        $ui.ComponentText.ToolTip = if ($componentOk) { $Context.Paths.FxapDecryptorDir } else { "缺少: $($componentInfo.Missing -join ', ')" }

        if ($state.Ready) {
            $ui.EnvironmentStatus.Text = if ($javaOk) { '运行环境就绪' } else { '可运行 · Lua 保留字节码' }
            $ui.EnvironmentStatus.Foreground = if ($javaOk) { (Get-CkThemeBrush '#31D69A') } else { (Get-CkThemeBrush '#F4B860') }
        } else {
            $ui.EnvironmentStatus.Text = '请处理缺失项'
            $ui.EnvironmentStatus.Foreground = (Get-CkThemeBrush '#EF7C86')
        }
        if (-not $state.Process) { $ui.StartButton.IsEnabled = [bool]$state.Ready }
        & $updateOutputPathAction
    }

    function Set-FxapRunning {
        param([bool]$Running)

        foreach ($control in @(
            $ui.InputBox,$ui.ChooseFolderButton,$ui.CfxKeyBox,$ui.NodeDownloadButton,$ui.NodeBrowseButton,
            $ui.JavaDownloadButton,$ui.JavaBrowseButton,$ui.DotNet8DownloadButton,$ui.VertexFixBox,$ui.AutoOpenBox
        )) {
            $control.IsEnabled = -not $Running
        }
        $ui.StartButton.IsEnabled = (-not $Running) -and [bool]$state.Ready
        $ui.StopButton.IsEnabled = $Running
        $ui.ProgressBar.IsIndeterminate = $false
        if ($Running) {
            $ui.ResultStatus.Text = '正在解密'
            $ui.ResultStatus.Foreground = (Get-CkThemeBrush '#72B7F2')
            $ui.StatusLine.Text = '正在识别 resource、获取密钥并解密文件，可随时停止。'
            $ui.ProgressBar.Value = 2
        }
    }

    function Reset-FxapStatistics {
        $state.ResourceTotal = 0
        $state.CompletedResources = 0
        $state.Decrypted = 0
        $state.Copied = 0
        $state.Lua = 0
        $state.Failures = 0
        $ui.ResourceCount.Text = '0'
        $ui.DecryptedCount.Text = '0'
        $ui.CopiedCount.Text = '0'
        $ui.LuaCount.Text = '0'
        $ui.FailureCount.Text = '0'
        $ui.ProgressBar.Value = 2
    }

    function Update-FxapProgressFromLine {
        param([string]$Line)

        Add-CkLogLine -TextBox $ui.LogBox -Line $Line
        [void]$state.LogBuilder.AppendLine($Line)
        if ($Line -match '^Resources:\s+(?<count>\d+)\s*$') {
            $state.ResourceTotal = [int]$Matches.count
            $ui.ResourceCount.Text = [string]$state.ResourceTotal
            return
        }
        if ($Line -match '^Output:\s+(?<path>.+?)\s*$') {
            $state.OutputPath = [string]$Matches.path
            $ui.OutputBox.Text = [string]$state.OutputPath
            return
        }
        if ($Line -match '^Vertex fix output:\s+(?<path>.+?)\s*$') {
            $state.VertexFixOutputPath = [string]$Matches.path
            $ui.ProgressBar.Value = [Math]::Max(98, [double]$ui.ProgressBar.Value)
            $ui.StatusLine.Text = "顶点修复副本已生成：$($state.VertexFixOutputPath)"
            return
        }
        if ($Line -match '^Vertex fix:\s+status=(?<status>\S+)\s+resources=(?<resources>\d+)\s+scanned=(?<scanned>\d+)\s+repaired=(?<repaired>\d+)\s+failed=(?<failed>\d+)\s*$') {
            $state.VertexFixStatus = [string]$Matches.status
            $state.VertexFixScanned = [int]$Matches.scanned
            $state.VertexFixRepaired = [int]$Matches.repaired
            $state.VertexFixFailed = [int]$Matches.failed
            $ui.ProgressBar.Value = 98
            $ui.StatusLine.Text = "顶点修复：扫描 $($Matches.scanned)，处理 $($Matches.repaired)，失败 $($Matches.failed)"
            return
        }
        if ($Line -match '^Vertex fix warning:') {
            $ui.ProgressBar.Value = [Math]::Max(96, [double]$ui.ProgressBar.Value)
            $ui.StatusLine.Text = '解密完成，正在生成副本并自动修复顶点。'
            return
        }
        if ($Line -match '^\[(?<current>\d+)/(?<total>\d+)\]\s+(?<name>.+)$') {
            $current = [int]$Matches.current
            $total = [Math]::Max(1, [int]$Matches.total)
            $state.ResourceTotal = $total
            $ui.ResourceCount.Text = [string]$total
            $ui.ProgressBar.Value = [Math]::Min(94, 5 + [int]((($current - 1) / $total) * 88))
            $ui.StatusLine.Text = "正在处理 $current/$total：$($Matches.name)"
            return
        }
        if ($Line -match '^\s*Done:\s+files=(?<files>\d+)\s+decrypted=(?<decrypted>\d+)\s+copied=(?<copied>\d+)\s+lua=(?<lua>\d+)\s+lua-fallback=(?<fallback>\d+)\s+failed=(?<failed>\d+)\s*$') {
            $state.CompletedResources++
            $state.Decrypted += [int]$Matches.decrypted
            $state.Copied += [int]$Matches.copied
            $state.Lua += [int]$Matches.lua + [int]$Matches.fallback
            $state.Failures += [int]$Matches.failed
            $ui.DecryptedCount.Text = [string]$state.Decrypted
            $ui.CopiedCount.Text = [string]$state.Copied
            $ui.LuaCount.Text = [string]$state.Lua
            $ui.FailureCount.Text = [string]$state.Failures
            if ($state.ResourceTotal -gt 0) {
                $ui.ProgressBar.Value = [Math]::Min(96, 5 + [int](($state.CompletedResources / $state.ResourceTotal) * 90))
            }
            return
        }
        if ($Line -match '^\s*Failed:\s+') {
            $state.Failures++
            $ui.FailureCount.Text = [string]$state.Failures
            return
        }
        if ($Line -match '^Finished:\s+resources=(?<resources>\d+)\s+resource-failures=(?<resourceFailures>\d+)\s+file-failures=(?<fileFailures>\d+)\s*$') {
            $state.ResourceTotal = [int]$Matches.resources
            $state.Failures = [int]$Matches.resourceFailures + [int]$Matches.fileFailures
            $ui.ResourceCount.Text = [string]$state.ResourceTotal
            $ui.FailureCount.Text = [string]$state.Failures
            $ui.ProgressBar.Value = 98
        }
    }

    function Save-FxapReport {
        param(
            [Parameter(Mandatory)][string]$Status,
            [int]$ExitCode
        )

        $finishedAt = Get-Date
        $startedAt = if ($state.StartedAt) { [datetime]$state.StartedAt } else { $finishedAt }
        $durationSeconds = [Math]::Round([Math]::Max(0, ($finishedAt - $startedAt).TotalSeconds), 3)
        $runName = (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 6)
        $runDir = Join-Path $state.ReportRoot $runName
        New-Item -ItemType Directory -Force -Path $runDir | Out-Null

        $logText = $state.LogBuilder.ToString().Trim()
        $logLines = if ($logText) { @($logText -split '\r?\n') } else { @() }
        $payload = [ordered]@{
            schemaVersion = 1
            tool = 'fxap-decryptor'
            status = $Status
            exitCode = $ExitCode
            startedAt = $startedAt.ToString('o')
            finishedAt = $finishedAt.ToString('o')
            durationSeconds = $durationSeconds
            input = [string]$state.InputPath
            output = [string]$state.OutputPath
            vertexFixOutput = [string]$state.VertexFixOutputPath
            vertexFixRequested = [bool]$state.VertexFixRequested
            vertexFix = [ordered]@{
                status = [string]$state.VertexFixStatus
                scanned = [int]$state.VertexFixScanned
                repaired = [int]$state.VertexFixRepaired
                failed = [int]$state.VertexFixFailed
                output = [string]$state.VertexFixOutputPath
            }
            autoOpenRequested = [bool]$state.AutoOpenRequested
            cfxKeyProvided = [bool]$state.CfxKeyProvided
            environment = [ordered]@{
                node = [ordered]@{
                    path = [string]$state.NodePath
                    version = [string]$state.NodeVersion
                }
                java = [ordered]@{
                    available = [bool]$state.JavaPath
                    path = [string]$state.JavaPath
                    version = [string]$state.JavaVersion
                }
            }
            summary = [ordered]@{
                resources = [int]$state.ResourceTotal
                decrypted = [int]$state.Decrypted
                copied = [int]$state.Copied
                lua = [int]$state.Lua
                failures = [int]$state.Failures
            }
            log = $logLines
        }

        $jsonPath = Join-Path $runDir 'report.json'
        [IO.File]::WriteAllText(
            $jsonPath,
            ($payload | ConvertTo-Json -Depth 10),
            (New-Object Text.UTF8Encoding($false))
        )

        $markdown = New-Object System.Collections.Generic.List[string]
        $markdown.Add('# FXAP 文件夹解密报告')
        $markdown.Add('')
        $markdown.Add("- 状态: $Status")
        $markdown.Add("- 退出码: $ExitCode")
        $markdown.Add("- 开始时间: $($startedAt.ToString('yyyy-MM-dd HH:mm:ss'))")
        $markdown.Add("- 结束时间: $($finishedAt.ToString('yyyy-MM-dd HH:mm:ss'))")
        $markdown.Add("- 用时: $durationSeconds 秒")
        $markdown.Add("- 输入目录: $($state.InputPath)")
        $markdown.Add("- 输出目录: $($state.OutputPath)")
        $markdown.Add($(if ($state.VertexFixRequested) { "- 顶点修复副本: $($state.VertexFixOutputPath)" } else { '- 顶点修复: 未启用' }))
        if ($state.VertexFixRequested) {
            $markdown.Add("- 顶点修复状态: $($state.VertexFixStatus)")
            $markdown.Add("- 顶点修复统计: 扫描 $($state.VertexFixScanned)，处理 $($state.VertexFixRepaired)，失败 $($state.VertexFixFailed)")
        }
        $markdown.Add($(if ($state.AutoOpenRequested) { '- 完成后自动打开: 是' } else { '- 完成后自动打开: 否' }))
        $markdown.Add($(if ($state.CfxKeyProvided) { '- CFX key: 已提供（密钥值未写入报告）' } else { '- CFX key: 未提供' }))
        $markdown.Add("- Node.js: $($state.NodeVersion) | $($state.NodePath)")
        $markdown.Add($(if ($state.JavaPath) { "- Java: $($state.JavaVersion) | $($state.JavaPath)" } else { '- Java: 未使用，Lua 字节码保留为 .luac' }))
        $markdown.Add('')
        $markdown.Add('## 统计')
        $markdown.Add('')
        $markdown.Add('| 资源 | 已解密 | 已复制 | Lua 输出 | 失败 |')
        $markdown.Add('| ---: | ---: | ---: | ---: | ---: |')
        $markdown.Add("| $($state.ResourceTotal) | $($state.Decrypted) | $($state.Copied) | $($state.Lua) | $($state.Failures) |")
        $markdown.Add('')
        $markdown.Add('## 日志')
        $markdown.Add('')
        $markdown.Add('~~~text')
        if ($logLines.Count) {
            foreach ($line in $logLines) { $markdown.Add([string]$line) }
        } else {
            $markdown.Add('组件没有返回日志。')
        }
        $markdown.Add('~~~')

        $markdownPath = Join-Path $runDir 'report.md'
        [IO.File]::WriteAllText(
            $markdownPath,
            ($markdown -join [Environment]::NewLine),
            (New-Object Text.UTF8Encoding($false))
        )
        return [pscustomobject]@{
            Markdown = [IO.Path]::GetFullPath($markdownPath)
            Json = [IO.Path]::GetFullPath($jsonPath)
        }
    }
    $getNodeInfoAction = (Get-Command Get-FxapNodeInfo).ScriptBlock.GetNewClosure()
    $getJavaInfoAction = (Get-Command Get-FxapJavaInfo).ScriptBlock.GetNewClosure()
    $getComponentInfoAction = (Get-Command Get-FxapComponentInfo).ScriptBlock.GetNewClosure()
    $getOutputPathAction = (Get-Command Get-FxapOutputPath).ScriptBlock.GetNewClosure()
    $updateOutputPathAction = (Get-Command Update-FxapOutputPath).ScriptBlock.GetNewClosure()
    $updateEnvironmentAction = (Get-Command Update-FxapEnvironment).ScriptBlock.GetNewClosure()
    $setRunningAction = (Get-Command Set-FxapRunning).ScriptBlock.GetNewClosure()
    $resetStatisticsAction = (Get-Command Reset-FxapStatistics).ScriptBlock.GetNewClosure()
    $parseOutputAction = (Get-Command Update-FxapProgressFromLine).ScriptBlock.GetNewClosure()
    $saveReportAction = (Get-Command Save-FxapReport).ScriptBlock.GetNewClosure()
    $setApiHealthStatusAction = (Get-Command Set-FxapApiHealthStatus).ScriptBlock.GetNewClosure()
    $startApiHealthCheckAction = (Get-Command Start-FxapApiHealthCheck).ScriptBlock.GetNewClosure()
    $apiHealthTick = {
        $task = $state.ApiHealthTask
        if (-not $task -or -not $task.IsCompleted) { return }

        $apiHealthTimer.Stop()
        $state.ApiHealthTask = $null
        $state.ApiLastCheck = Get-Date
        try {
            if ($task.IsCanceled) { throw 'API 健康检查超时。' }
            if ($task.IsFaulted) { throw $task.Exception.GetBaseException() }
            $response = $task.GetAwaiter().GetResult()
            try {
                $statusCode = [int]$response.StatusCode
                if ($statusCode -ge 200 -and $statusCode -lt 300) {
                    & $setApiHealthStatusAction -Status available -Detail "HTTP $statusCode"
                } else {
                    & $setApiHealthStatusAction -Status unavailable -Detail "HTTP $statusCode"
                }
            } finally {
                if ($response) { $response.Dispose() }
            }
        } catch {
            $detail = $_.Exception.Message
            if (-not $detail) { $detail = '无法连接 API。' }
            & $setApiHealthStatusAction -Status unavailable -Detail $detail
        }
    }.GetNewClosure()
    $apiHealthTimer.Add_Tick($apiHealthTick)
    $activateAction = {
        & $updateEnvironmentAction
        & $startApiHealthCheckAction
    }.GetNewClosure()

    $showPageError = {
        param([string]$message)
        $ui.ResultStatus.Text = '操作失败'
        $ui.ResultStatus.Foreground = (Get-CkThemeBrush '#EF6B73')
        $ui.StatusLine.Text = $message
        Add-CkLogLine -TextBox $ui.LogBox -Line "[工具箱] $message"
        [System.Windows.MessageBox]::Show($message, 'CK免费工具箱 - FXAP 文件夹解密') | Out-Null
    }.GetNewClosure()

    $openNodeDownloadAction = {
        Start-Process -FilePath 'https://nodejs.org/en/download'
    }.GetNewClosure()

    $selectNodeAction = {
        $settings = Get-CkDependencySettings
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Title = '选择 Node.js 主程序 node.exe'
        $dialog.Filter = 'Node.js 主程序 (node.exe)|node.exe|可执行文件 (*.exe)|*.exe'
        $dialog.CheckFileExists = $true
        $dialog.Multiselect = $false
        $dialog.RestoreDirectory = $true
        if ($settings.NodePath -and (Test-Path -LiteralPath ([string]$settings.NodePath) -PathType Leaf)) {
            $dialog.InitialDirectory = Split-Path -Parent ([string]$settings.NodePath)
            $dialog.FileName = [string]$settings.NodePath
        }
        if (-not $dialog.ShowDialog()) { return }
        $nodePath = Set-CkDependencyPath -Dependency Node -Path ([string]$dialog.FileName)
        $info = Test-CkNodeExecutable -Path $nodePath
        if (-not $info.Ok) { throw [string]$info.Reason }
        & $updateEnvironmentAction
    }.GetNewClosure()

    $openJavaDownloadAction = {
        Start-Process -FilePath 'https://adoptium.net/temurin/releases/?version=17&os=windows&arch=x64&package=jre'
    }.GetNewClosure()

    $openDotNet8DownloadAction = {
        Start-Process -FilePath 'https://dotnet.microsoft.com/download/dotnet/8.0/runtime'
    }.GetNewClosure()

    $selectJavaAction = {
        $settings = Get-CkDependencySettings
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = '选择 Java 8 或更高版本的 JDK/JRE 安装目录（推荐 Java 17）'
        $dialog.ShowNewFolderButton = $false
        $initialPath = ''
        if ($settings.JavaPath -and (Test-Path -LiteralPath ([string]$settings.JavaPath) -PathType Leaf)) {
            $initialPath = Split-Path -Parent ([string]$settings.JavaPath)
            if ((Split-Path -Leaf $initialPath) -ieq 'bin') { $initialPath = Split-Path -Parent $initialPath }
        }
        if ($initialPath -and (Test-Path -LiteralPath $initialPath -PathType Container)) {
            $dialog.SelectedPath = $initialPath
        }
        try {
            if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
            $selected = [IO.Path]::GetFullPath($dialog.SelectedPath)
        } finally {
            $dialog.Dispose()
        }
        $javaPath = Set-CkDependencyPath -Dependency Java -Path $selected
        $info = Test-CkJavaExecutable -Path $javaPath
        if (-not $info.Ok) { throw [string]$info.Reason }
        & $updateEnvironmentAction
    }.GetNewClosure()

    $chooseFolderAction = {
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = '选择包含 .fxap 的单个 resource 或父目录'
        $dialog.ShowNewFolderButton = $false
        $currentPath = $ui.InputBox.Text.Trim()
        if ($currentPath -and (Test-Path -LiteralPath $currentPath -PathType Container)) {
            $dialog.SelectedPath = $currentPath
        }
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $ui.InputBox.Text = [IO.Path]::GetFullPath($dialog.SelectedPath)
            }
        } finally {
            $dialog.Dispose()
        }
    }.GetNewClosure()

    $openOutputAction = {
        $path = $ui.OutputBox.Text.Trim()
        if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Container)) { throw "输出目录不存在: $path" }
        Start-Process -FilePath explorer.exe -ArgumentList @($path)
    }.GetNewClosure()

    $openReportAction = {
        $path = [string]$state.ReportPath
        if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw '本次 FXAP 解密报告不存在，请先完成一次任务。'
        }
        Start-Process -FilePath notepad.exe -ArgumentList ('"{0}"' -f $path) -ErrorAction Stop
    }.GetNewClosure()

    $openReportHistoryAction = {
        $path = [string]$state.ReportRoot
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            New-Item -ItemType Directory -Force -Path $path | Out-Null
        }
        Start-Process -FilePath explorer.exe -ArgumentList @($path)
    }.GetNewClosure()
    function Start-FxapDecryption {
        if ($state.Process -and -not $state.Process.Process.HasExited) { throw '已有 FXAP 解密任务正在运行。' }
        $nodeInfo = & $getNodeInfoAction
        if (-not $nodeInfo.Ok) { throw [string]$nodeInfo.Reason }
        $componentInfo = & $getComponentInfoAction
        if (-not $componentInfo.Ok) { throw 'fxap_only 组件未安装或不完整，请先点击顶部“安装组件”。' }

        $inputPath = $ui.InputBox.Text.Trim()
        if (-not $inputPath -or -not (Test-Path -LiteralPath $inputPath -PathType Container)) { throw "输入目录不存在: $inputPath" }
        $inputPath = [IO.Path]::GetFullPath($inputPath).TrimEnd('\')
        $driveRoot = [IO.Path]::GetPathRoot($inputPath).TrimEnd('\')
        if ($inputPath.Equals($driveRoot, [StringComparison]::OrdinalIgnoreCase)) { throw '不能把整个磁盘作为 FXAP 扫描目录。' }

        $cfxKey = $ui.CfxKeyBox.Password.Trim()
        if ($cfxKey -and $cfxKey -notmatch '^cfxk_[A-Za-z0-9_-]+$') {
            throw 'CFX server key 格式无效，应以 cfxk_ 开头；不需要时请留空。'
        }

        & $updateOutputPathAction
        $javaInfo = & $getJavaInfoAction
        $vertexFixRequested = [bool]$ui.VertexFixBox.IsChecked
        $autoOpenRequested = [bool]$ui.AutoOpenBox.IsChecked
        if ($vertexFixRequested) {
            $dotNet8Info = Get-CkDotNet8Info
            if (-not $dotNet8Info.Ok) { throw '自动修复顶点需要 .NET 8 Runtime，请先点击页面顶部 .NET 8 的“官网”按钮安装。' }
        }
        $arguments = @($Context.Paths.FxapDecryptorScript)
        if ($vertexFixRequested) { $arguments += '--vertex-fix' }
        if ($cfxKey) { $arguments += $cfxKey }
        $arguments += $inputPath
        if ($javaInfo.Ok) { $arguments += [string]$javaInfo.Path }

        $state.ReportPath = ''
        $state.JsonReportPath = ''
        $state.StartedAt = Get-Date
        $state.InputPath = $inputPath
        $state.CfxKeyProvided = [bool]$cfxKey
        $state.VertexFixRequested = $vertexFixRequested
        $state.AutoOpenRequested = $autoOpenRequested
        $state.VertexFixOutputPath = ''
        $state.VertexFixStatus = if ($vertexFixRequested) { 'pending' } else { 'disabled' }
        $state.VertexFixScanned = 0
        $state.VertexFixRepaired = 0
        $state.VertexFixFailed = 0
        $state.NodePath = [string]$nodeInfo.Path
        $state.NodeVersion = [string]$nodeInfo.Version
        $state.JavaPath = if ($javaInfo.Ok) { [string]$javaInfo.Path } else { '' }
        $state.JavaVersion = if ($javaInfo.Ok) { [string]$javaInfo.Version } else { '' }
        [void]$state.LogBuilder.Clear()
        $ui.OpenReportButton.IsEnabled = $false
        & $resetStatisticsAction
        $ui.LogBox.Clear()
        Add-CkLogLine -TextBox $ui.LogBox -Line '[工具箱] 正在启动 fxap_only；接口鉴权配置不会由工具箱读取或传递。'
        [void]$state.LogBuilder.AppendLine('[工具箱] 正在启动 fxap_only；接口鉴权配置不会由工具箱读取或传递。')
        if (-not $javaInfo.Ok) {
            Add-CkLogLine -TextBox $ui.LogBox -Line '[工具箱] 未检测到 Java，任务继续；Lua 反编译失败时将保留 .luac。'
            [void]$state.LogBuilder.AppendLine('[工具箱] 未检测到 Java，任务继续；Lua 反编译失败时将保留 .luac。')
        }
        $state.CancelRequested = $false
        & $setRunningAction $true

        $callbackState = $state
        $callbackUi = $ui
        $callbackParse = $parseOutputAction
        $callbackSetRunning = $setRunningAction
        $callbackUpdateEnvironment = $updateEnvironmentAction
        $callbackSaveReport = $saveReportAction
        $callbackVertexFixRequested = $vertexFixRequested
        $callbackAutoOpenRequested = $autoOpenRequested
        $onOutput = {
            param($line)
            & $callbackParse $line
        }.GetNewClosure()
        $onProcessError = {
            param($message)
            $callbackUi.StatusLine.Text = $message
        }.GetNewClosure()
        $onExit = {
            param($exitCode)
            $cancelled = $callbackState.CancelRequested
            $callbackState.CancelRequested = $false
            $callbackState.Process = $null
            & $callbackSetRunning $false
            $callbackUi.OpenOutputButton.IsEnabled = [bool]($callbackState.OutputPath -and (Test-Path -LiteralPath $callbackState.OutputPath -PathType Container))
            $reportStatus = if ($cancelled) { 'cancelled' } elseif ($exitCode -eq 0) { 'success' } elseif ($exitCode -eq 2) { 'partial' } else { 'failed' }
            if ($cancelled) {
                $callbackUi.ResultStatus.Text = '已停止'
                $callbackUi.ResultStatus.Foreground = (Get-CkThemeBrush '#F4B860')
                $callbackUi.StatusLine.Text = '任务已停止；已输出的文件不会自动删除。'
            } elseif ($exitCode -eq 0) {
                $callbackUi.ResultStatus.Text = '解密完成'
                $callbackUi.ResultStatus.Foreground = (Get-CkThemeBrush '#31D69A')
                $callbackUi.ProgressBar.Value = 100
                $callbackUi.StatusLine.Text = "已完成 $($callbackState.ResourceTotal) 个 resource，输出位于 $($callbackState.OutputPath)"
            } elseif ($exitCode -eq 2) {
                $vertexFailed = $callbackState.VertexFixRequested -and $callbackState.VertexFixStatus -in @('failed','partial')
                $callbackUi.ResultStatus.Text = if ($vertexFailed) { '解密完成，顶点修复存在失败' } else { '完成，存在文件失败' }
                $callbackUi.ResultStatus.Foreground = (Get-CkThemeBrush '#F4B860')
                $callbackUi.ProgressBar.Value = 100
                $callbackUi.StatusLine.Text = if ($vertexFailed) {
                    "原解密输出已保留；顶点修复处理 $($callbackState.VertexFixRepaired)，失败 $($callbackState.VertexFixFailed)，请检查日志。"
                } else {
                    "任务完成但有 $($callbackState.Failures) 项失败，请检查日志和 .failed.txt。"
                }
            } else {
                $callbackUi.ResultStatus.Text = '解密失败'
                $callbackUi.ResultStatus.Foreground = (Get-CkThemeBrush '#EF6B73')
                $callbackUi.StatusLine.Text = "fxap_only 退出码: $exitCode，请查看日志。"
            }
            if (-not $cancelled -and $callbackAutoOpenRequested -and $reportStatus -in @('success','partial')) {
                $openPath = [string]$callbackState.OutputPath
                if ($callbackVertexFixRequested -and $callbackState.VertexFixOutputPath -and
                    (Test-Path -LiteralPath $callbackState.VertexFixOutputPath -PathType Container)) {
                    $openPath = [string]$callbackState.VertexFixOutputPath
                }
                if ($openPath -and (Test-Path -LiteralPath $openPath -PathType Container)) {
                    try {
                        Start-Process -FilePath explorer.exe -ArgumentList @($openPath) -ErrorAction Stop | Out-Null
                    } catch {
                        Add-CkLogLine -TextBox $callbackUi.LogBox -Line "[工具箱] 自动打开输出文件夹失败：$($_.Exception.Message)"
                    }
                }
            }
            try {
                $report = & $callbackSaveReport -Status $reportStatus -ExitCode $exitCode
                $callbackState.ReportPath = [string]$report.Markdown
                $callbackState.JsonReportPath = [string]$report.Json
                $callbackUi.OpenReportButton.IsEnabled = $true
                Add-CkLogLine -TextBox $callbackUi.LogBox -Line "[工具箱] 本次报告: $($callbackState.ReportPath)"
            } catch {
                $callbackState.ReportPath = ''
                $callbackState.JsonReportPath = ''
                $callbackUi.OpenReportButton.IsEnabled = $false
                Add-CkLogLine -TextBox $callbackUi.LogBox -Line "[工具箱] 报告保存失败: $($_.Exception.Message)"
            }
            & $callbackUpdateEnvironment
        }.GetNewClosure()

        try {
            $state.Process = Start-CkLoggedProcess -FileName ([string]$nodeInfo.Path) -Arguments $arguments -WorkingDirectory $Context.Paths.FxapDecryptorDir -Dispatcher $Context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onProcessError
        } catch {
            & $setRunningAction $false
            throw
        }
    }

    $startAction = (Get-Command Start-FxapDecryption).ScriptBlock.GetNewClosure()
    $runAction = { & $startAction }.GetNewClosure()
    $stopAction = {
        if (-not $state.Process -or $state.Process.Process.HasExited) { return }
        $state.CancelRequested = $true
        $ui.StopButton.IsEnabled = $false
        $ui.ResultStatus.Text = '正在停止'
        $ui.StatusLine.Text = '正在停止 Node.js 解密进程及其子进程...'
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

    $inputChangedHandler = { & $updateOutputPathAction }.GetNewClosure()
    $ui.InputBox.Add_TextChanged($inputChangedHandler)
    Register-CkButtonAction -Button $ui.NodeDownloadButton -Action $openNodeDownloadAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.NodeBrowseButton -Action $selectNodeAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.JavaDownloadButton -Action $openJavaDownloadAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.DotNet8DownloadButton -Action $openDotNet8DownloadAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.JavaBrowseButton -Action $selectJavaAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseFolderButton -Action $chooseFolderAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenOutputButton -Action $openOutputAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenReportButton -Action $openReportAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenReportHistoryButton -Action $openReportHistoryAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StartButton -Action $runAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StopButton -Action $stopAction -OnError $showPageError

    & $activateAction
    return [pscustomobject]@{
        Id = 'fxap-decryptor'
        Title = 'FXAP 文件夹解密'
        Icon = '◇'
        Root = $root
        Activate = $activateAction
    }
}
