$script:CkLogBoxStates = @{}

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
    [xml]$xml = $Xaml
    $reader = New-Object System.Xml.XmlNodeReader $xml
    $root = [Windows.Markup.XamlReader]::Load($reader)
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
    $Ellipse.Fill = if ($Ok) { '#31D69A' } else { '#EF6B73' }
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
        $ellipse.Fill = '#1A1C1E'
        $ellipse.Stroke = '#1A1C1E'
        $ellipse.StrokeThickness = 2
        $text = New-Object System.Windows.Controls.TextBlock
        $text.Text = [string]$i
        $text.Foreground = '#676C75'
        $text.FontSize = 18
        $text.FontWeight = 'Bold'
        $text.HorizontalAlignment = 'Center'
        $text.VerticalAlignment = 'Center'
        [void]$grid.Children.Add($ellipse)
        [void]$grid.Children.Add($text)
        [void]$Panel.Children.Add($grid)
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
            $ellipse.Fill = '#113A2C'
            $ellipse.Stroke = '#168961'
            $text.Text = '✓'
            $text.Foreground = '#31D69A'
        } elseif ($number -eq $Step) {
            $ellipse.Fill = '#102440'
            $ellipse.Stroke = '#17477F'
            $text.Text = [string]$number
            $text.Foreground = '#58A6FF'
        } else {
            $ellipse.Fill = '#1A1C1E'
            $ellipse.Stroke = '#1A1C1E'
            $text.Text = [string]$number
            $text.Foreground = '#676C75'
        }
    }
}

Export-ModuleMember -Function Enable-CkPageMouseWheelRouting, Import-CkXaml, Get-CkNamedControls, Register-CkButtonAction, Register-CkTextChangedAction, Set-CkStatusDot, Add-CkLogLine, New-CkStepPanel, Set-CkStepState
