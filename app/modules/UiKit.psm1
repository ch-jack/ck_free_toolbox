$script:CkLogBoxStates = @{}

$script:CkCurrentTheme = 'Dark'
$script:CkThemeRoots = New-Object System.Collections.ArrayList
$script:CkRuntimeThemeBrushes = @{}
$script:CkRuntimeThemeBrushSpecs = @{}

$script:CkThemeTokens = @{
    Dark = @{
        Canvas = '#080A0E'
        Chrome = '#0A0D12'
        Sidebar = '#0B0E13'
        Surface = '#10141A'
        SurfaceRaised = '#151A22'
        SurfaceSoft = '#0D1117'
        Border = '#252C37'
        BorderSoft = '#1C222C'
        Text = '#EDF1F7'
        Text2 = '#AAB3C1'
        Text3 = '#778396'
        Accent = '#68AEFC'
        AccentStrong = '#82BBFC'
        AccentSoft = '#172B43'
        AccentBorder = '#27466A'
        Success = '#46D6A3'
        SuccessSoft = '#10281F'
        SuccessBorder = '#24533F'
        Warning = '#F4B860'
        WarningSoft = '#3A2514'
        WarningBorder = '#6E512A'
        Danger = '#EF7C86'
        DangerSoft = '#5A2026'
        DangerBorder = '#7C3038'
        Purple = '#A99CFF'
        PurpleSoft = '#353051'
        OnAccent = '#07101B'
    }
    Light = @{
        Canvas = '#F3F6FA'
        Chrome = '#FCFDFE'
        Sidebar = '#F8FAFD'
        Surface = '#FCFDFE'
        SurfaceRaised = '#F1F4F8'
        SurfaceSoft = '#F7F9FC'
        Border = '#D6DEE9'
        BorderSoft = '#E7EBF1'
        Text = '#182230'
        Text2 = '#3D4A5D'
        Text3 = '#5E6C80'
        Accent = '#2D72BC'
        AccentStrong = '#1F68B7'
        AccentSoft = '#E7F1FC'
        AccentBorder = '#8CB9E8'
        Success = '#167552'
        SuccessSoft = '#E6F4EF'
        SuccessBorder = '#9FCDBB'
        Warning = '#8A5A00'
        WarningSoft = '#FFF3D8'
        WarningBorder = '#E4BD7A'
        Danger = '#B42332'
        DangerSoft = '#FDECEE'
        DangerBorder = '#E0A8AE'
        Purple = '#6741B6'
        PurpleSoft = '#F0EBFF'
        OnAccent = '#F7FBFF'
    }
}

function Add-CkThemeRoleAliases {
    param(
        [Parameter(Mandatory)][hashtable]$Map,
        [Parameter(Mandatory)][string]$Role,
        [Parameter(Mandatory)][string[]]$Colors
    )

    foreach ($color in $Colors) {
        $Map[$color.ToUpperInvariant()] = $Role
    }
}

$script:CkStatusRoles = @{}
Add-CkThemeRoleAliases -Map $script:CkStatusRoles -Role 'AccentStrong' -Colors @('#58A6FF','#72B7F2','#7DB5FF','#8FC7F3')
Add-CkThemeRoleAliases -Map $script:CkStatusRoles -Role 'Success' -Colors @('#31D69A','#54E0A9','#4CB7A5','#76D7C4','#8BDDBD','#9DE0C6')
Add-CkThemeRoleAliases -Map $script:CkStatusRoles -Role 'Warning' -Colors @('#D69B2D','#D7C38D','#D8B968','#E58A4E','#F4B860')
Add-CkThemeRoleAliases -Map $script:CkStatusRoles -Role 'Danger' -Colors @('#D89078','#EF6B73','#EF7C86','#EF9A9A','#F28B94','#FF9CA3')
Add-CkThemeRoleAliases -Map $script:CkStatusRoles -Role 'Purple' -Colors @('#8B7CF6','#9B7BFF','#9B8CFF','#A99CFF','#B56BFF','#D5D0FF')

$script:CkBackgroundRoles = @{}
Add-CkThemeRoleAliases -Map $script:CkBackgroundRoles -Role 'Chrome' -Colors @('#070707')
Add-CkThemeRoleAliases -Map $script:CkBackgroundRoles -Role 'Canvas' -Colors @('#090A0A','#0A0B0B')
Add-CkThemeRoleAliases -Map $script:CkBackgroundRoles -Role 'Surface' -Colors @('#101214')
Add-CkThemeRoleAliases -Map $script:CkBackgroundRoles -Role 'SurfaceSoft' -Colors @('#0D0F11','#0D0F12','#0D1014','#0E1012','#111820','#111A24','#1B1E24','#1B222A')
Add-CkThemeRoleAliases -Map $script:CkBackgroundRoles -Role 'SurfaceRaised' -Colors @('#11131A','#111419','#15181C','#151820','#151A20','#16181B','#171A1F','#171B22','#191C21','#1A1C1E','#2A2D33','#2A2E37')
Add-CkThemeRoleAliases -Map $script:CkBackgroundRoles -Role 'AccentSoft' -Colors @('#102440','#14213A','#173055','#24415F','#2B303A','#315A91')
Add-CkThemeRoleAliases -Map $script:CkBackgroundRoles -Role 'SuccessSoft' -Colors @('#101A16','#113A2C','#12382D','#124834')
Add-CkThemeRoleAliases -Map $script:CkBackgroundRoles -Role 'WarningSoft' -Colors @('#15110E','#181710','#3A2514','#4A4020','#5A3B21','#5D3A24')
Add-CkThemeRoleAliases -Map $script:CkBackgroundRoles -Role 'DangerSoft' -Colors @('#5A2026')
Add-CkThemeRoleAliases -Map $script:CkBackgroundRoles -Role 'PurpleSoft' -Colors @('#353051')

$script:CkForegroundRoles = @{}
Add-CkThemeRoleAliases -Map $script:CkForegroundRoles -Role 'Text' -Colors @('#FFFFFF','#F4F7FB','#E5E7EB','#E7E9ED','#D5D8DE','#D5DAE2','#D7DAE0','#D7DCE3')
Add-CkThemeRoleAliases -Map $script:CkForegroundRoles -Role 'Text2' -Colors @('#A4AAB4','#AAB2BE','#B8C0CC','#C4CBD5')
Add-CkThemeRoleAliases -Map $script:CkForegroundRoles -Role 'Text3' -Colors @('#30343B','#596273','#5D626B','#616874','#636872','#666C76','#676C75','#686E78','#69707A','#6B7280','#6E7580','#6F7580','#777B83','#777C84','#7C8088','#858B96','#868A92','#8A8F98','#8B9099','#8B929E','#8B95A3','#8F91A1','#8F98A5')
Add-CkThemeRoleAliases -Map $script:CkForegroundRoles -Role 'OnAccent' -Colors @('#07101B')

$script:CkBorderRoles = @{}
Add-CkThemeRoleAliases -Map $script:CkBorderRoles -Role 'Border' -Colors @('#1E2633','#20242B','#20242C','#242833','#242A33','#242A34','#2A2D33','#2A2E37','#2B303A','#30343B','#303641','#343A46','#343D49','#3A424E','#3B4048','#465266','#4B5563','#586474')
Add-CkThemeRoleAliases -Map $script:CkBorderRoles -Role 'AccentBorder' -Colors @('#17477F','#24415F','#2B4A68','#315A91','#465266')
Add-CkThemeRoleAliases -Map $script:CkBorderRoles -Role 'SuccessBorder' -Colors @('#168961','#1E4D3C','#277A5E')
Add-CkThemeRoleAliases -Map $script:CkBorderRoles -Role 'WarningBorder' -Colors @('#4A4020','#5D3A24')

function Resolve-CkThemeColor {
    param(
        [Parameter(Mandatory)][string]$Color,
        [string]$Property = 'Generic',
        [ValidateSet('Dark','Light')][string]$Theme = $script:CkCurrentTheme
    )

    $normalized = $Color.Trim().ToUpperInvariant()
    if ($normalized -notmatch '^#[0-9A-F]{6}$') { return $Color }

    $role = $null
    if ($script:CkStatusRoles.ContainsKey($normalized)) {
        $role = [string]$script:CkStatusRoles[$normalized]
    } else {
        $propertyName = ($Property -split '\.')[-1]
        if ($propertyName -eq 'Background') {
            if ($script:CkBackgroundRoles.ContainsKey($normalized)) {
                $role = [string]$script:CkBackgroundRoles[$normalized]
            }
        } elseif ($propertyName -in @('BorderBrush','Stroke')) {
            if ($script:CkBorderRoles.ContainsKey($normalized)) {
                $role = [string]$script:CkBorderRoles[$normalized]
            } elseif ($script:CkBackgroundRoles.ContainsKey($normalized)) {
                $role = 'Border'
            }
        } elseif ($propertyName -in @('Foreground','CaretBrush','SelectionTextBrush')) {
            if ($script:CkForegroundRoles.ContainsKey($normalized)) {
                $role = [string]$script:CkForegroundRoles[$normalized]
            }
        } elseif ($propertyName -eq 'Fill') {
            if ($script:CkBackgroundRoles.ContainsKey($normalized)) {
                $role = [string]$script:CkBackgroundRoles[$normalized]
            } elseif ($script:CkForegroundRoles.ContainsKey($normalized)) {
                $role = [string]$script:CkForegroundRoles[$normalized]
            }
        } else {
            if ($script:CkForegroundRoles.ContainsKey($normalized)) {
                $role = [string]$script:CkForegroundRoles[$normalized]
            } elseif ($script:CkBackgroundRoles.ContainsKey($normalized)) {
                $role = [string]$script:CkBackgroundRoles[$normalized]
            } elseif ($script:CkBorderRoles.ContainsKey($normalized)) {
                $role = [string]$script:CkBorderRoles[$normalized]
            }
        }
    }

    if (-not $role) { return $normalized }
    return [string]$script:CkThemeTokens[$Theme][$role]
}

function New-CkSolidColorBrush {
    param([Parameter(Mandatory)][string]$Color)

    $parsed = [System.Windows.Media.ColorConverter]::ConvertFromString($Color)
    return [System.Windows.Media.SolidColorBrush]::new($parsed)
}

function Get-CkThemeBrush {
    param(
        [Parameter(Mandatory)][string]$Color,
        [string]$Property = 'Generic'
    )

    $normalized = $Color.Trim().ToUpperInvariant()
    $cacheKey = "$Property|$normalized"
    if (-not $script:CkRuntimeThemeBrushes.ContainsKey($cacheKey)) {
        $resolved = Resolve-CkThemeColor -Color $normalized -Property $Property -Theme $script:CkCurrentTheme
        $script:CkRuntimeThemeBrushes[$cacheKey] = New-CkSolidColorBrush -Color $resolved
        $script:CkRuntimeThemeBrushSpecs[$cacheKey] = [pscustomobject]@{ Color = $normalized; Property = $Property }
    }
    return $script:CkRuntimeThemeBrushes[$cacheKey]
}

function Get-CkTheme {
    return $script:CkCurrentTheme
}

function Get-CkSystemTheme {
    try {
        $value = Get-ItemPropertyValue -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -ErrorAction Stop
        if ([int]$value -eq 1) { return 'Light' }
    } catch { }
    return 'Dark'
}

function Resolve-CkThemePreference {
    param([ValidateSet('system','light','dark')][string]$Preference = 'system')

    if ($Preference -eq 'light') { return 'Light' }
    if ($Preference -eq 'dark') { return 'Dark' }
    return Get-CkSystemTheme
}

function Update-CkThemeResources {
    param([Parameter(Mandatory)]$Root)

    if (-not $Root.PSObject.Properties['Resources'] -or -not $Root.Resources) { return }
    foreach ($key in @($Root.Resources.Keys)) {
        $keyText = [string]$key
        if ($keyText -notmatch '^CkTheme_(?<Property>[A-Za-z]+)_(?<Color>[0-9A-F]{6})$') { continue }
        $property = [string]$Matches.Property
        $original = '#' + [string]$Matches.Color
        $resolved = Resolve-CkThemeColor -Color $original -Property $property -Theme $script:CkCurrentTheme
        $existing = $Root.Resources[$key]
        if ($existing -is [System.Windows.Media.SolidColorBrush] -and -not $existing.IsFrozen) {
            $existing.Color = [System.Windows.Media.ColorConverter]::ConvertFromString($resolved)
        } else {
            $Root.Resources[$key] = New-CkSolidColorBrush -Color $resolved
        }
    }
}

function Set-CkTheme {
    param([Parameter(Mandatory)][ValidateSet('Dark','Light')][string]$Theme)

    $script:CkCurrentTheme = $Theme
    foreach ($cacheKey in @($script:CkRuntimeThemeBrushes.Keys)) {
        $spec = $script:CkRuntimeThemeBrushSpecs[$cacheKey]
        $resolved = Resolve-CkThemeColor -Color $spec.Color -Property $spec.Property -Theme $Theme
        $brush = $script:CkRuntimeThemeBrushes[$cacheKey]
        if ($brush -is [System.Windows.Media.SolidColorBrush] -and -not $brush.IsFrozen) {
            $brush.Color = [System.Windows.Media.ColorConverter]::ConvertFromString($resolved)
        }
    }
    foreach ($reference in @($script:CkThemeRoots)) {
        $root = if ($reference -is [System.WeakReference]) { $reference.Target } else { $reference }
        if ($root) {
            Update-CkThemeResources -Root $root
        } else {
            [void]$script:CkThemeRoots.Remove($reference)
        }
    }
    return $script:CkCurrentTheme
}

function ConvertTo-CkThemedXaml {
    param([Parameter(Mandatory)][string]$Xaml)

    [xml]$xml = $Xaml
    $rootNode = $xml.DocumentElement
    $presentationNamespace = 'http://schemas.microsoft.com/winfx/2006/xaml/presentation'
    $xNamespace = 'http://schemas.microsoft.com/winfx/2006/xaml'
    $brushProperties = @('Background','Foreground','BorderBrush','Fill','Stroke','CaretBrush','SelectionBrush','SelectionTextBrush')
    $resourceSpecs = [ordered]@{}

    foreach ($node in @($xml.SelectNodes('//*[@*]'))) {
        foreach ($attribute in @($node.Attributes)) {
            if ($attribute.Value -notmatch '^#[0-9A-Fa-f]{6}$') { continue }
            $property = [string]$attribute.LocalName
            if ($node.LocalName -eq 'Setter' -and $attribute.LocalName -eq 'Value') {
                $property = [string]$node.GetAttribute('Property')
            }
            $property = ($property -split '\.')[-1]
            if ($property -notin $brushProperties) { continue }

            $original = $attribute.Value.ToUpperInvariant()
            $key = 'CkTheme_{0}_{1}' -f $property, $original.TrimStart('#')
            $attribute.Value = '{DynamicResource ' + $key + '}'
            if (-not $resourceSpecs.Contains($key)) {
                $resourceSpecs[$key] = [pscustomobject]@{ Property = $property; Color = $original }
            }
        }
    }

    $resourcesNode = $null
    foreach ($child in @($rootNode.ChildNodes)) {
        if ($child.LocalName -eq ($rootNode.LocalName + '.Resources')) {
            $resourcesNode = $child
            break
        }
    }
    if (-not $resourcesNode) {
        $resourcesNode = $xml.CreateElement(($rootNode.LocalName + '.Resources'), $presentationNamespace)
        if ($rootNode.FirstChild) {
            [void]$rootNode.InsertBefore($resourcesNode, $rootNode.FirstChild)
        } else {
            [void]$rootNode.AppendChild($resourcesNode)
        }
    }

    foreach ($entry in $resourceSpecs.GetEnumerator()) {
        $brushNode = $xml.CreateElement('SolidColorBrush', $presentationNamespace)
        $keyAttribute = $xml.CreateAttribute('x', 'Key', $xNamespace)
        $keyAttribute.Value = [string]$entry.Key
        [void]$brushNode.Attributes.Append($keyAttribute)
        $colorAttribute = $xml.CreateAttribute('Color')
        $colorAttribute.Value = Resolve-CkThemeColor -Color $entry.Value.Color -Property $entry.Value.Property -Theme $script:CkCurrentTheme
        [void]$brushNode.Attributes.Append($colorAttribute)
        [void]$resourcesNode.AppendChild($brushNode)
    }

    return $xml.OuterXml
}

function Enable-CkPageMouseWheelRouting {
    param([Parameter(Mandatory)]$Root)

    if (-not ($Root -is [System.Windows.Controls.ScrollViewer])) { return }

    $pageScrollViewer = $Root
    $handler = [System.Windows.Input.MouseWheelEventHandler]{
        param($sender, $eventArgs)

        if ($eventArgs.Handled -or
            (([System.Windows.Input.Keyboard]::Modifiers -band [System.Windows.Input.ModifierKeys]::Control) -eq [System.Windows.Input.ModifierKeys]::Control)) {
            return
        }

        $current = $eventArgs.OriginalSource
        $nestedScrollViewer = $null
        while ($current -and $current -ne $pageScrollViewer) {
            if ($current -is [System.Windows.Controls.ScrollViewer]) {
                $nestedScrollViewer = $current
                break
            }

            $parent = $null
            try { $parent = [System.Windows.Media.VisualTreeHelper]::GetParent($current) } catch { }
            if (-not $parent -and $current -is [System.Windows.FrameworkContentElement]) {
                $parent = $current.Parent
            } elseif (-not $parent -and $current -is [System.Windows.FrameworkElement]) {
                $parent = $current.Parent
            }
            $current = $parent
        }
        if (-not $nestedScrollViewer -or $pageScrollViewer.ScrollableHeight -le 0) { return }

        $wheelLines = [System.Windows.SystemParameters]::WheelScrollLines
        $distance = if ($wheelLines -eq -1) {
            [Math]::Max(48.0, $pageScrollViewer.ViewportHeight * 0.85)
        } else {
            16.0 * [Math]::Max(1, [Math]::Min(6, $wheelLines))
        }
        $change = -([double]$eventArgs.Delta / 120.0) * $distance
        $target = [Math]::Max(0.0, [Math]::Min($pageScrollViewer.ScrollableHeight, $pageScrollViewer.VerticalOffset + $change))
        if ([Math]::Abs($target - $pageScrollViewer.VerticalOffset) -lt 0.1) { return }

        $eventArgs.Handled = $true
        $pageScrollViewer.ScrollToVerticalOffset($target)
    }.GetNewClosure()

    $Root.AddHandler([System.Windows.UIElement]::PreviewMouseWheelEvent, $handler, $true)
}

function Import-CkXaml {
    param([Parameter(Mandatory)][string]$Xaml)
    [xml]$xml = ConvertTo-CkThemedXaml -Xaml $Xaml
    $reader = New-Object System.Xml.XmlNodeReader $xml
    $root = [Windows.Markup.XamlReader]::Load($reader)
    [void]$script:CkThemeRoots.Add([System.WeakReference]::new($root))
    Enable-CkPageMouseWheelRouting -Root $root
    return $root
}

function Get-CkNamedControls {
    param(
        [Parameter(Mandatory)]$Root,
        [Parameter(Mandatory)][string[]]$Names
    )
    $map = @{}
    foreach ($name in $Names) {
        $map[$name] = $Root.FindName($name)
    }
    return $map
}

function Register-CkButtonAction {
    param(
        [Parameter(Mandatory)]$Button,
        [Parameter(Mandatory)][scriptblock]$Action,
        [scriptblock]$OnError
    )

    $handler = {
        param($sender, $eventArgs)
        try {
            & $Action $sender $eventArgs
        } catch {
            $message = $_.Exception.Message
            if ($OnError) {
                & $OnError $message
            } else {
                [System.Windows.MessageBox]::Show(
                    $message,
                    'CK免费工具箱 - 操作失败',
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                ) | Out-Null
            }
        }
    }.GetNewClosure()

    $Button.Add_Click($handler)
}

function Register-CkTextChangedAction {
    param(
        [Parameter(Mandatory)]$TextBox,
        [Parameter(Mandatory)][scriptblock]$Action,
        [scriptblock]$OnError
    )

    $handler = {
        param($sender, $eventArgs)
        try {
            & $Action $sender $eventArgs
        } catch {
            $message = $_.Exception.Message
            if ($OnError) { & $OnError $message }
        }
    }.GetNewClosure()

    $TextBox.Add_TextChanged($handler)
}

function Set-CkStatusDot {
    param($Ellipse, [bool]$Ok)
    $Ellipse.Fill = if ($Ok) { Get-CkThemeBrush '#31D69A' -Property Fill } else { Get-CkThemeBrush '#EF6B73' -Property Fill }
}

function Add-CkLogLine {
    param(
        [Parameter(Mandatory)]$TextBox,
        [Parameter(Mandatory)][string]$Line,
        [int]$MaxChars = 80000
    )

    if (-not $script:CkLogBoxStates.ContainsKey($TextBox)) {
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(50)
        $state = [pscustomobject]@{
            Timer = $timer
            InternalChange = $false
            ShouldFollow = $false
            TextChangedHandler = $null
            TimerHandler = $null
        }

        $textChangedHandler = {
            if (-not $state.InternalChange) {
                $state.ShouldFollow = $false
                $state.Timer.Stop()
            }
        }.GetNewClosure()
        $timerHandler = {
            $state.Timer.Stop()
            if (-not $state.ShouldFollow) { return }
            $state.ShouldFollow = $false
            try { $TextBox.ScrollToEnd() } catch { }
        }.GetNewClosure()
        $state.TextChangedHandler = $textChangedHandler
        $state.TimerHandler = $timerHandler
        $TextBox.Add_TextChanged($textChangedHandler)
        $timer.Add_Tick($timerHandler)
        $script:CkLogBoxStates[$TextBox] = $state
    }

    $state = $script:CkLogBoxStates[$TextBox]
    if (-not $state.Timer.IsEnabled) {
        $distanceFromBottom = [Math]::Max(0, $TextBox.ExtentHeight - $TextBox.ViewportHeight - $TextBox.VerticalOffset)
        $state.ShouldFollow = (-not $TextBox.IsLoaded) -or ($distanceFromBottom -le 24)
    }

    $state.InternalChange = $true
    try {
        $TextBox.AppendText($Line + [Environment]::NewLine)
        if ($TextBox.Text.Length -gt $MaxChars) {
            $TextBox.Text = $TextBox.Text.Substring($TextBox.Text.Length - $MaxChars)
        }
    } finally {
        $state.InternalChange = $false
    }

    if ($state.ShouldFollow -and -not $state.Timer.IsEnabled) {
        $state.Timer.Start()
    }
}

function New-CkStepPanel {
    param([Parameter(Mandatory)]$Panel)
    $Panel.Children.Clear()
    for ($i = 1; $i -le 5; $i++) {
        $grid = New-Object System.Windows.Controls.Grid
        $grid.Tag = $i
        $ellipse = New-Object System.Windows.Shapes.Ellipse
        $ellipse.Width = 40
        $ellipse.Height = 40
        $ellipse.Fill = Get-CkThemeBrush '#1A1C1E' -Property Fill
        $ellipse.Stroke = Get-CkThemeBrush '#1A1C1E' -Property Stroke
        $ellipse.StrokeThickness = 2
        $text = New-Object System.Windows.Controls.TextBlock
        $text.Text = [string]$i
        $text.Foreground = Get-CkThemeBrush '#676C75' -Property Foreground
        $text.FontSize = 18
        $text.FontWeight = 'Bold'
        $text.HorizontalAlignment = 'Center'
        $text.VerticalAlignment = 'Center'
        [void]$grid.Children.Add($ellipse)
        [void]$grid.Children.Add($text)
        [void]$Panel.Children.Add($grid)
    }
}

function Set-CkDialogInitialPath {
    param(
        [Parameter(Mandatory)]$Dialog,
        [AllowNull()][AllowEmptyString()][string]$Path,
        [switch]$ForSave
    )

    # Text-box input is only a navigation hint: it must not block the picker.
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    try {
        $candidate = $Path.Trim()
        if ($candidate.Length -ge 2 -and $candidate.StartsWith('"') -and $candidate.EndsWith('"')) {
            $candidate = $candidate.Substring(1, $candidate.Length - 2).Trim()
        }
        if ([string]::IsNullOrWhiteSpace($candidate)) { return }
        $candidate = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($candidate)
        $candidate = [IO.Path]::GetFullPath($candidate)
        if ($candidate.IndexOfAny([IO.Path]::GetInvalidPathChars()) -ge 0 -or $candidate.IndexOfAny([char[]]'*?') -ge 0) { return }
        $isFile = [IO.File]::Exists($candidate)
        $isDirectory = [IO.Directory]::Exists($candidate)
        $directory = $candidate
        while (-not [IO.Directory]::Exists($directory)) {
            $parent = [IO.Path]::GetDirectoryName($directory)
            if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $directory) { return }
            $directory = $parent
        }
    } catch {
        return
    }

    if ($Dialog -is [System.Windows.Forms.FolderBrowserDialog]) {
        $Dialog.SelectedPath = $directory
    } else {
        $Dialog.InitialDirectory = $directory
        if ($isFile) {
            $Dialog.FileName = $candidate
        } elseif ($ForSave -and -not $isDirectory) {
            $fileName = [IO.Path]::GetFileName($candidate)
            if ($fileName -and $fileName.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -lt 0) {
                $Dialog.FileName = $fileName
            }
        }
    }
}

function Set-CkStepState {
    param($Panel, [int]$Step, [string]$Label, $LabelControl)
    if ($LabelControl) { $LabelControl.Text = "步骤 $Step/5: $Label" }
    foreach ($child in $Panel.Children) {
        $number = [int]$child.Tag
        $ellipse = $child.Children[0]
        $text = $child.Children[1]
        if ($number -lt $Step) {
            $ellipse.Fill = Get-CkThemeBrush '#113A2C' -Property Fill
            $ellipse.Stroke = Get-CkThemeBrush '#168961' -Property Stroke
            $text.Text = '✓'
            $text.Foreground = Get-CkThemeBrush '#31D69A' -Property Foreground
        } elseif ($number -eq $Step) {
            $ellipse.Fill = Get-CkThemeBrush '#102440' -Property Fill
            $ellipse.Stroke = Get-CkThemeBrush '#17477F' -Property Stroke
            $text.Text = [string]$number
            $text.Foreground = Get-CkThemeBrush '#58A6FF' -Property Foreground
        } else {
            $ellipse.Fill = Get-CkThemeBrush '#1A1C1E' -Property Fill
            $ellipse.Stroke = Get-CkThemeBrush '#1A1C1E' -Property Stroke
            $text.Text = [string]$number
            $text.Foreground = Get-CkThemeBrush '#676C75' -Property Foreground
        }
    }
}

Export-ModuleMember -Function Enable-CkPageMouseWheelRouting, Import-CkXaml, Get-CkNamedControls, Register-CkButtonAction, Register-CkTextChangedAction, Set-CkStatusDot, Add-CkLogLine, New-CkStepPanel, Set-CkStepState, Set-CkDialogInitialPath, Get-CkThemeBrush, Get-CkTheme, Get-CkSystemTheme, Resolve-CkThemePreference, Set-CkTheme
