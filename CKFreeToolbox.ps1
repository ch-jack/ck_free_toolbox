Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.IO.Compression.FileSystem

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PortableRenderer = Join-Path $ScriptRoot 'vehicle_renderer\render_all_vehicles.py'
$PortableManifest = Join-Path $ScriptRoot 'package-manifest.json'
$IsPortable = (Test-Path -LiteralPath $PortableManifest -PathType Leaf) -or (Test-Path -LiteralPath $PortableRenderer -PathType Leaf)
$WorkspaceRoot = if ($IsPortable) { $ScriptRoot } else { Split-Path -Parent $ScriptRoot }
$AppRoot = Join-Path $ScriptRoot 'app'
$ModuleRoot = Join-Path $AppRoot 'modules'
$PageRoot = Join-Path $AppRoot 'pages'
$ConfigPath = Join-Path $AppRoot 'config\tools.json'
$IconPath = Join-Path $ScriptRoot 'static\cklogo.ico'

Import-Module (Join-Path $ModuleRoot 'UiKit.psm1') -Force
Import-Module (Join-Path $ModuleRoot 'AssetScanner.psm1') -Force
Import-Module (Join-Path $ModuleRoot 'EnvironmentProbe.psm1') -Force
Import-Module (Join-Path $ModuleRoot 'ProcessRunner.psm1') -Force

$context = [pscustomobject]@{
    Paths = [pscustomobject]@{
        ScriptRoot = $ScriptRoot
        AppRoot = $AppRoot
        WorkspaceRoot = $WorkspaceRoot
        RuntimeRoot = Join-Path $WorkspaceRoot 'runtime'
        RendererDir = Join-Path $WorkspaceRoot 'vehicle_renderer'
        RenderScript = Join-Path $WorkspaceRoot 'vehicle_renderer\render_all_vehicles.py'
        WallfixDir = Join-Path $WorkspaceRoot 'nui-wallfix'
        WallfixScript = Join-Path $WorkspaceRoot 'nui-wallfix\nui-wallfix.py'
        WallfixProviders = Join-Path $WorkspaceRoot 'nui-wallfix\providers.json'
        DefaultWallfixInput = ''
        DefaultInput = Join-Path $WorkspaceRoot 'TestVeh'
        DefaultRenderOut = Join-Path $WorkspaceRoot 'TestVeh\_vehicle_renders'
    }
    Dispatcher = $null
}

$shellXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="CK免费工具箱" Width="1180" Height="740" MinWidth="860" MinHeight="560"
        WindowStartupLocation="CenterScreen" Background="#090A0A" FontFamily="Microsoft YaHei" Foreground="#E5E7EB">
  <Window.Resources>
    <Style TargetType="Button">
      <Setter Property="Foreground" Value="#E5E7EB"/>
      <Setter Property="Background" Value="#171A1F"/>
      <Setter Property="BorderBrush" Value="#2B303A"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="9,6"/>
      <Setter Property="Cursor" Value="Hand"/>
    </Style>
    <Style TargetType="TextBox">
      <Setter Property="Foreground" Value="#E5E7EB"/>
      <Setter Property="Background" Value="#1B1E24"/>
      <Setter Property="BorderBrush" Value="#343A46"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="10,6"/>
    </Style>
    <Style TargetType="ComboBox">
      <Setter Property="Foreground" Value="#E5E7EB"/>
      <Setter Property="Background" Value="#1B1E24"/>
    </Style>
    <Style x:Key="CkScrollPageButton" TargetType="{x:Type RepeatButton}">
      <Setter Property="Focusable" Value="False"/>
      <Setter Property="OverridesDefaultStyle" Value="True"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="{x:Type RepeatButton}">
            <Border Background="Transparent"/>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="CkScrollThumb" TargetType="{x:Type Thumb}">
      <Setter Property="MinWidth" Value="28"/>
      <Setter Property="MinHeight" Value="28"/>
      <Setter Property="Background" Value="#3A424E"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="{x:Type Thumb}">
            <Border x:Name="ThumbBody" Margin="2" Background="{TemplateBinding Background}" CornerRadius="4"/>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="ThumbBody" Property="Background" Value="#586474"/>
              </Trigger>
              <Trigger Property="IsDragging" Value="True">
                <Setter TargetName="ThumbBody" Property="Background" Value="#31D69A"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <ControlTemplate x:Key="CkVerticalScrollBar" TargetType="{x:Type ScrollBar}">
      <Grid Width="{TemplateBinding Width}" Background="{TemplateBinding Background}">
        <Track x:Name="PART_Track" Orientation="Vertical" IsDirectionReversed="True">
          <Track.DecreaseRepeatButton>
            <RepeatButton Style="{StaticResource CkScrollPageButton}" Command="{x:Static ScrollBar.PageUpCommand}"/>
          </Track.DecreaseRepeatButton>
          <Track.Thumb>
            <Thumb Style="{StaticResource CkScrollThumb}"/>
          </Track.Thumb>
          <Track.IncreaseRepeatButton>
            <RepeatButton Style="{StaticResource CkScrollPageButton}" Command="{x:Static ScrollBar.PageDownCommand}"/>
          </Track.IncreaseRepeatButton>
        </Track>
      </Grid>
    </ControlTemplate>
    <ControlTemplate x:Key="CkHorizontalScrollBar" TargetType="{x:Type ScrollBar}">
      <Grid Height="{TemplateBinding Height}" Background="{TemplateBinding Background}">
        <Track x:Name="PART_Track" Orientation="Horizontal">
          <Track.DecreaseRepeatButton>
            <RepeatButton Style="{StaticResource CkScrollPageButton}" Command="{x:Static ScrollBar.PageLeftCommand}"/>
          </Track.DecreaseRepeatButton>
          <Track.Thumb>
            <Thumb Style="{StaticResource CkScrollThumb}"/>
          </Track.Thumb>
          <Track.IncreaseRepeatButton>
            <RepeatButton Style="{StaticResource CkScrollPageButton}" Command="{x:Static ScrollBar.PageRightCommand}"/>
          </Track.IncreaseRepeatButton>
        </Track>
      </Grid>
    </ControlTemplate>
    <Style TargetType="{x:Type ScrollBar}">
      <Setter Property="Width" Value="10"/>
      <Setter Property="Background" Value="#0D1014"/>
      <Setter Property="Opacity" Value="0.78"/>
      <Setter Property="Template" Value="{StaticResource CkVerticalScrollBar}"/>
      <Style.Triggers>
        <Trigger Property="Orientation" Value="Horizontal">
          <Setter Property="Width" Value="Auto"/>
          <Setter Property="Height" Value="10"/>
          <Setter Property="Template" Value="{StaticResource CkHorizontalScrollBar}"/>
        </Trigger>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Opacity" Value="1"/>
        </Trigger>
      </Style.Triggers>
    </Style>
  </Window.Resources>
  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height="60"/>
      <RowDefinition Height="*"/>
    </Grid.RowDefinitions>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="104"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>

    <Border Grid.ColumnSpan="2" Background="#070707" BorderBrush="#20242C" BorderThickness="0,0,0,1">
      <Grid Margin="18,0">
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
          <Border Width="36" Height="36" Background="#0B0B0D" CornerRadius="8" BorderBrush="#2B303A" BorderThickness="1" Margin="0,0,12,0">
            <Grid>
              <TextBlock Text="CK" Foreground="#FFFFFF" FontWeight="Black" FontSize="13" HorizontalAlignment="Center" VerticalAlignment="Center"/>
              <Border Width="9" Height="9" Background="#31D69A" CornerRadius="4" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,4,4"/>
            </Grid>
          </Border>
          <TextBlock Text="CK免费工具箱" FontSize="20" FontWeight="Bold" VerticalAlignment="Center"/>
          <TextBlock Text="v1.0.2" Foreground="#42464D" FontSize="13" Margin="12,2,0,0" VerticalAlignment="Center"/>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
          <TextBlock Text="客户端直跑 · 无后端服务" Foreground="#6E7580" FontSize="13" Margin="0,3,16,0"/>
          <Border Background="#101A16" BorderBrush="#1E4D3C" BorderThickness="1" CornerRadius="6" Padding="10,6">
            <StackPanel Orientation="Horizontal">
              <Ellipse Width="8" Height="8" Fill="#31D69A" Margin="0,0,7,0" VerticalAlignment="Center"/>
              <TextBlock Text="本机运行" Foreground="#8BDDBD" FontSize="13"/>
            </StackPanel>
          </Border>
        </StackPanel>
      </Grid>
    </Border>

    <Border Grid.Row="1" Background="#0A0B0B" BorderBrush="#20242C" BorderThickness="0,0,1,0">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <StackPanel Margin="10,16,10,12">
          <TextBlock Text="工具" Foreground="#616874" FontSize="13" FontWeight="Bold" Margin="6,0,0,10"/>
          <StackPanel x:Name="NavHost"/>
        </StackPanel>
        <TextBlock Grid.Row="2" Text="POWERED BY CK" Foreground="#3B4048" FontSize="11" TextAlignment="Center" Margin="0,0,0,18"/>
      </Grid>
    </Border>

    <Grid Grid.Row="1" Grid.Column="1">
      <Grid.RowDefinitions>
        <RowDefinition Height="64"/>
        <RowDefinition Height="*"/>
      </Grid.RowDefinitions>
      <Border Background="#090A0A" BorderBrush="#171B22" BorderThickness="0,0,0,1">
        <Grid Margin="28,0,32,0">
          <StackPanel VerticalAlignment="Center">
            <TextBlock x:Name="PageTitle" Text="模型自动截图" FontSize="24" FontWeight="Bold"/>
            <TextBlock x:Name="PageSubtitle" Text="可扩展客户端工具箱" Foreground="#6E7580" FontSize="12" Margin="0,3,0,0"/>
          </StackPanel>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
            <TextBlock x:Name="ComponentStatusText" AutomationProperties.AutomationId="Tool.ComponentStatusText"
                       Text="检测组件" Foreground="#8B929E" FontSize="12" VerticalAlignment="Center" Margin="0,0,10,0"/>
            <Button x:Name="ComponentActionButton" AutomationProperties.AutomationId="Tool.ComponentActionButton"
                    Content="检查更新" Width="104" Height="34" Margin="0,0,8,0"
                    Background="#151A20" BorderBrush="#343D49" Foreground="#B8C0CC" FontSize="13"/>
            <Button x:Name="OpenSourceButton" AutomationProperties.AutomationId="Tool.OpenSourceButton"
                    Content="GitHub 开源地址 ↗" Width="142" Height="34"
                    Background="#111820" BorderBrush="#2B4A68" Foreground="#72B7F2" FontSize="13" FontWeight="SemiBold"
                    ToolTip="打开当前项目的 GitHub 仓库"/>
          </StackPanel>
        </Grid>
      </Border>
      <Grid x:Name="PageHost" Grid.Row="1" Background="#090A0A"/>
    </Grid>
  </Grid>
</Window>
"@

$window = Import-CkXaml $shellXaml

function Set-CkResponsiveWindowSize {
    param([Parameter(Mandatory)]$Window)

    $workArea = [System.Windows.SystemParameters]::WorkArea
    $workWidth = if ($workArea.Width -gt 0) { $workArea.Width } else { 1366 }
    $workHeight = if ($workArea.Height -gt 0) { $workArea.Height } else { 768 }

    $minimumWidth = [Math]::Min(860, [Math]::Max(720, [Math]::Floor($workWidth * 0.72)))
    $minimumHeight = [Math]::Min(560, [Math]::Max(460, [Math]::Floor($workHeight * 0.68)))
    $targetWidth = [Math]::Min(1180, [Math]::Floor($workWidth * 0.78))
    $targetHeight = [Math]::Min(740, [Math]::Floor($workHeight * 0.76))

    $Window.MinWidth = $minimumWidth
    $Window.MinHeight = $minimumHeight
    $Window.Width = [Math]::Max($minimumWidth, $targetWidth)
    $Window.Height = [Math]::Max($minimumHeight, $targetHeight)
}

Set-CkResponsiveWindowSize -Window $window
if (Test-Path -LiteralPath $IconPath -PathType Leaf) {
    $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create(
        [Uri]::new($IconPath, [UriKind]::Absolute)
    )
}
$context.Dispatcher = $window.Dispatcher
$navHost = $window.FindName('NavHost')
$pageHost = $window.FindName('PageHost')
$pageTitle = $window.FindName('PageTitle')
$pageSubtitle = $window.FindName('PageSubtitle')
$componentStatusText = $window.FindName('ComponentStatusText')
$componentActionButton = $window.FindName('ComponentActionButton')
$openSourceButton = $window.FindName('OpenSourceButton')

$tools = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
$pages = @{}
$buttons = @{}
$toolConfigs = @{}
$componentWorker = Join-Path $AppRoot 'workers\ComponentWorker.ps1'
$componentState = [pscustomobject]@{
    CurrentToolId = ''
    Process = $null
    Remote = @{}
    Checked = @{}
}

function New-NavButton {
    param($Tool)

    $button = New-Object System.Windows.Controls.Button
    $button.Tag = $Tool.id
    [System.Windows.Automation.AutomationProperties]::SetName($button, [string]$Tool.title)
    [System.Windows.Automation.AutomationProperties]::SetAutomationId($button, "Nav-$($Tool.id)")
    $button.Height = 64
    $button.Margin = '0,0,0,10'
    $button.Background = '#111419'
    $button.BorderBrush = '#242A34'

    $stack = New-Object System.Windows.Controls.StackPanel
    $stack.HorizontalAlignment = 'Center'
    $icon = New-Object System.Windows.Controls.TextBlock
    $icon.Text = [string]$Tool.icon
    $icon.FontSize = if ([string]$Tool.icon -eq 'A⊞') { 18 } else { 22 }
    $icon.HorizontalAlignment = 'Center'
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = [string]$Tool.title
    $label.FontSize = 11
    $label.Foreground = '#8B929E'
    $label.HorizontalAlignment = 'Center'
    $label.Margin = '0,3,0,0'
    [void]$stack.Children.Add($icon)
    [void]$stack.Children.Add($label)
    $button.Content = $stack
    return $button
}

function Get-CkLocalComponentState {
    param($Tool)

    if (-not $Tool -or -not $Tool.PSObject.Properties['component']) { return $null }
    $workspace = [IO.Path]::GetFullPath($context.Paths.WorkspaceRoot).TrimEnd('\')
    $target = [IO.Path]::GetFullPath((Join-Path $workspace ([string]$Tool.component.installDir))).TrimEnd('\')
    if (-not $target.StartsWith($workspace + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "组件目录越界: $target"
    }

    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($relative in @($Tool.component.requiredFiles)) {
        $required = [IO.Path]::GetFullPath((Join-Path $target ([string]$relative)))
        if (-not $required.StartsWith($target + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "组件必需文件越界: $relative"
        }
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
            $missing.Add([string]$relative)
        }
    }

    $version = ''
    $manifestPath = Join-Path $target '.ck-component.json'
    if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
        try {
            $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $version = [string]$manifest.releaseTag
        } catch { }
    }

    return [pscustomobject]@{
        Installed = ($missing.Count -eq 0)
        MissingFiles = @($missing)
        LocalVersion = $version
        Target = $target
    }
}
function Update-CkComponentHeader {
    $tool = $toolConfigs[$componentState.CurrentToolId]
    if (-not $tool -or -not $tool.PSObject.Properties['component']) {
        $componentStatusText.Visibility = 'Collapsed'
        $componentActionButton.Visibility = 'Collapsed'
        return
    }

    $componentStatusText.Visibility = 'Visible'
    $componentActionButton.Visibility = 'Visible'
    if ($componentState.Process -and $componentState.Process.ToolId -eq $componentState.CurrentToolId) {
        $componentStatusText.Text = if ($componentState.Process.Action -eq 'check') { '正在检查 Release' } else { '正在安装组件' }
        $componentStatusText.Foreground = '#72B7F2'
        $componentActionButton.Content = if ($componentState.Process.Action -eq 'check') { '检查中...' } else { '安装中...' }
        $componentActionButton.IsEnabled = $false
        return
    }

    $local = & $getLocalComponentStateAction $tool
    $remote = if ($componentState.Remote.ContainsKey($componentState.CurrentToolId)) { $componentState.Remote[$componentState.CurrentToolId] } else { $null }
    $componentActionButton.IsEnabled = $true
    if (-not $local.Installed) {
        $componentStatusText.Text = '组件缺失'
        $componentStatusText.Foreground = '#EF7C86'
        $componentActionButton.Content = '安装组件'
        $componentActionButton.Tag = 'install'
        $componentActionButton.Foreground = '#54E0A9'
        return
    }
    if ($remote -and $remote.updateAvailable) {
        $latestVersion = [string]$remote.latestVersion
        $componentStatusText.Text = if ($latestVersion) { "发现新版本 $latestVersion" } else { '发现新版本' }
        $componentStatusText.Foreground = '#F4B860'
        $componentActionButton.Content = '更新组件'
        $componentActionButton.Tag = 'install'
        $componentActionButton.Foreground = '#F4B860'
        return
    }

    $componentStatusText.Text = if ($local.LocalVersion) { "已安装 $($local.LocalVersion)" } else { '组件已安装' }
    $componentStatusText.Foreground = '#31D69A'
    $componentActionButton.Content = '检查更新'
    $componentActionButton.Tag = 'check'
    $componentActionButton.Foreground = '#B8C0CC'
}

function Start-CkComponentOperation {
    param([ValidateSet('check','install')][string]$Action, [string]$ToolId)

    if ($componentState.Process) { return }
    $tool = $toolConfigs[$ToolId]
    if (-not $tool) { throw "工具配置不存在: $ToolId" }
    if (-not (Test-Path -LiteralPath $componentWorker -PathType Leaf)) {
        throw "组件工作器不存在: $componentWorker"
    }

    if ($Action -eq 'install') {
        $local = & $getLocalComponentStateAction $tool
        $verb = if ($local.Installed) { '更新' } else { '安装' }
        $answer = [System.Windows.MessageBox]::Show(
            "即将从 GitHub Release $verb $($tool.title) 组件。`n`n仓库: $($tool.component.repo)`n现有组件会先备份。是否继续？",
            "确认$verb组件",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Information
        )
        if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
    }

    $output = New-Object Text.StringBuilder
    $callbackOutput = $output
    $callbackState = $componentState
    $callbackToolId = $ToolId
    $callbackAction = $Action
    $callbackRefresh = $refreshComponentHeaderAction
    $callbackPages = $pages

    $onOutput = {
        param($line)
        [void]$callbackOutput.AppendLine($line)
    }.GetNewClosure()
    $onError = {
        param($message)
        if ($callbackState.CurrentToolId -eq $callbackToolId) {
            $componentStatusText.Text = $message
            $componentStatusText.Foreground = '#EF7C86'
        }
    }.GetNewClosure()
    $onExit = {
        param($exitCode)
        $callbackState.Process = $null
        $raw = $callbackOutput.ToString().Trim()
        $payload = $null
        $lines = @($raw -split '\r?\n')
        for ($i = $lines.Count - 1; $i -ge 0 -and -not $payload; $i--) {
            try { $payload = $lines[$i] | ConvertFrom-Json } catch { }
        }
        if (-not $payload) {
            $payload = [pscustomobject]@{ status = 'error'; error = if ($raw) { $raw } else { "组件工作器退出码: $exitCode" } }
        }
        $callbackState.Remote[$callbackToolId] = $payload
        if ($callbackState.CurrentToolId -eq $callbackToolId) { & $callbackRefresh }
        if ($payload.status -eq 'error' -or $exitCode -ne 0) {
            [System.Windows.MessageBox]::Show(
                $(if ($payload.error) { [string]$payload.error } else { "组件操作失败，退出码: $exitCode" }),
                'CK免费工具箱 - 组件管理',
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            ) | Out-Null
            return
        }
        if ($callbackAction -eq 'install') {
            if ($callbackPages[$callbackToolId].Activate) { & $callbackPages[$callbackToolId].Activate }
            [System.Windows.MessageBox]::Show(
                "$($callbackPages[$callbackToolId].Title) 组件已安装到最新版本。",
                'CK免费工具箱 - 组件管理',
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            ) | Out-Null
        }
    }.GetNewClosure()

    $powershellExe = Join-Path $PSHOME 'powershell.exe'
    $arguments = @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', $componentWorker,
        '-Action', $Action,
        '-ToolId', $ToolId,
        '-ConfigPath', $ConfigPath,
        '-WorkspaceRoot', $context.Paths.WorkspaceRoot
    )
    $runtime = Start-CkLoggedProcess -FileName $powershellExe -Arguments $arguments -WorkingDirectory $ScriptRoot -Dispatcher $context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onError
    $componentState.Process = [pscustomobject]@{ ToolId = $ToolId; Action = $Action; Runtime = $runtime }
    & $refreshComponentHeaderAction
}
function Show-ToolPage {
    param([string]$Id)

    $toolConfig = $toolConfigs[$Id]
    if (-not $toolConfig) { throw "工具配置不存在: $Id" }
    $componentState.CurrentToolId = $Id
    foreach ($key in $pages.Keys) {
        $pages[$key].Root.Visibility = if ($key -eq $Id) { 'Visible' } else { 'Collapsed' }
        $buttons[$key].Background = if ($key -eq $Id) { '#2B303A' } else { '#111419' }
        $buttons[$key].BorderBrush = if ($key -eq $Id) { '#465266' } else { '#242A34' }
    }

    $pageTitle.Text = $pages[$Id].Title
    $pageSubtitle.Text = '模块化页面 · 本机组件 · GitHub 更新'
    $sourceUrl = if ($toolConfig.PSObject.Properties['sourceUrl']) { [string]$toolConfig.sourceUrl } else { '' }
    $openSourceButton.Tag = $sourceUrl
    $openSourceButton.ToolTip = if ($sourceUrl) { $sourceUrl } else { '当前项目未配置开源地址' }
    $openSourceButton.Visibility = if ($sourceUrl) { 'Visible' } else { 'Collapsed' }
    if ($pages[$Id].Activate) { & $pages[$Id].Activate }
    & $refreshComponentHeaderAction


}

$getLocalComponentStateAction = (Get-Command Get-CkLocalComponentState).ScriptBlock.GetNewClosure()
$refreshComponentHeaderAction = (Get-Command Update-CkComponentHeader).ScriptBlock.GetNewClosure()
$startComponentOperationAction = (Get-Command Start-CkComponentOperation).ScriptBlock.GetNewClosure()
$showToolPageAction = (Get-Command Show-ToolPage).ScriptBlock.GetNewClosure()

$openSourceAction = {
    $url = [string]$openSourceButton.Tag
    $uri = $null
    if ([string]::IsNullOrWhiteSpace($url) -or -not [Uri]::TryCreate($url, [UriKind]::Absolute, [ref]$uri)) {
        throw '当前项目未配置有效的开源地址。'
    }
    if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'github.com') {
        throw "仅允许打开 GitHub HTTPS 地址: $url"
    }
    Start-Process -FilePath $uri.AbsoluteUri
}.GetNewClosure()
$componentAction = {
    $action = [string]$componentActionButton.Tag
    if ($action -notin @('check','install')) { $action = 'check' }
    & $startComponentOperationAction $action $componentState.CurrentToolId
}.GetNewClosure()
Register-CkButtonAction -Button $openSourceButton -Action $openSourceAction
Register-CkButtonAction -Button $componentActionButton -Action $componentAction

foreach ($tool in $tools) {
    $toolConfigs[$tool.id] = $tool
    $pagePath = Join-Path $PageRoot $tool.page
    if (-not (Test-Path -LiteralPath $pagePath)) {
        throw "页面脚本不存在: $pagePath"
    }

    . $pagePath
    $page = & $tool.factory -Context $context
    $page.Root.Visibility = 'Collapsed'
    [void]$pageHost.Children.Add($page.Root)
    $pages[$tool.id] = $page

    $button = New-NavButton -Tool $tool
    $buttons[$tool.id] = $button
    $navAction = {
        param($sender, $eventArgs)
        & $showToolPageAction -Id ([string]$sender.Tag)
    }.GetNewClosure()
    Register-CkButtonAction -Button $button -Action $navAction
    [void]$navHost.Children.Add($button)
}

$defaultTool = @($tools | Where-Object { $_.default })[0]
if (-not $defaultTool) { $defaultTool = @($tools)[0] }
& $showToolPageAction -Id $defaultTool.id

[void]$window.ShowDialog()
