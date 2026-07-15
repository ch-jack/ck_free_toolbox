function Get-CkDependencySettingsPath {
    $root = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CKFreeToolbox'
    return Join-Path $root 'settings.json'
}

function Get-CkDependencySettings {
    $settings = [ordered]@{ BlenderPath = '' }
    $path = Get-CkDependencySettingsPath
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        try {
            $saved = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($saved.PSObject.Properties['BlenderPath']) {
                $settings.BlenderPath = [string]$saved.BlenderPath
            }
        } catch { }
    }
    return [pscustomobject]$settings
}

function Set-CkDependencyPath {
    param(
        [Parameter(Mandatory)][ValidateSet('Blender')][string]$Dependency,
        [Parameter(Mandatory)][string]$Path
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $fullPath)) { throw "选择的路径不存在: $fullPath" }
    if ($Dependency -eq 'Blender') {
        $resolved = Find-CkDependencyFile -Root $fullPath -FileName 'blender.exe'
        if (-not $resolved) { throw "选择的位置没有找到 blender.exe: $fullPath" }
        $fullPath = $resolved
    }
    $settings = Get-CkDependencySettings
    $settings.BlenderPath = $fullPath
    $settingsPath = Get-CkDependencySettingsPath
    $settingsRoot = Split-Path -Parent $settingsPath
    New-Item -ItemType Directory -Path $settingsRoot -Force | Out-Null
    [IO.File]::WriteAllText(
        $settingsPath,
        ($settings | ConvertTo-Json -Depth 3),
        (New-Object Text.UTF8Encoding($false))
    )
    return $fullPath
}

function Find-CkDependencyFile {
    param([string]$Root, [string]$FileName)

    if ([string]::IsNullOrWhiteSpace($Root) -or -not (Test-Path -LiteralPath $Root)) { return '' }
    if (Test-Path -LiteralPath $Root -PathType Leaf) {
        return $(if ([IO.Path]::GetFileName($Root) -ieq $FileName) { [IO.Path]::GetFullPath($Root) } else { '' })
    }

    $queue = New-Object 'System.Collections.Generic.Queue[object]'
    $queue.Enqueue([pscustomobject]@{ Path = [IO.Path]::GetFullPath($Root); Depth = 0 })
    $visited = 0
    while ($queue.Count -gt 0 -and $visited -lt 512) {
        $current = $queue.Dequeue()
        $visited++
        $candidate = Join-Path $current.Path $FileName
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return [IO.Path]::GetFullPath($candidate) }
        if ($current.Depth -ge 4) { continue }
        foreach ($directory in @(Get-ChildItem -LiteralPath $current.Path -Directory -ErrorAction SilentlyContinue)) {
            $queue.Enqueue([pscustomobject]@{ Path = $directory.FullName; Depth = $current.Depth + 1 })
        }
    }
    return ''
}

function Get-CkBlenderInfo {
    param([string]$WorkspaceRoot, $Settings)

    if (-not $Settings) { $Settings = Get-CkDependencySettings }
    $candidates = @()
    if ($Settings.BlenderPath) {
        $selected = Find-CkDependencyFile -Root ([string]$Settings.BlenderPath) -FileName 'blender.exe'
        if ($selected) { $candidates += $selected }
    }
    foreach ($envName in @('BLENDER_EXE', 'BLENDER_PATH')) {
        $value = [Environment]::GetEnvironmentVariable($envName)
        if ($value) {
            $resolved = Find-CkDependencyFile -Root $value -FileName 'blender.exe'
            if ($resolved) { $candidates += $resolved }
        }
    }

    $programFiles = [Environment]::GetFolderPath('ProgramFiles')
    $blenderRoot = Join-Path $programFiles 'Blender Foundation'
    if (Test-Path -LiteralPath $blenderRoot -PathType Container) {
        $candidates += @(Get-ChildItem -LiteralPath $blenderRoot -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            ForEach-Object { Join-Path $_.FullName 'blender.exe' })
    }
    $candidates += @(
        'D:\Blender 5.0\blender.exe',
        'C:\Program Files\Blender Foundation\Blender 5.1\blender.exe',
        'C:\Program Files\Blender Foundation\Blender 5.0\blender.exe',
        'C:\Program Files\Blender Foundation\Blender 4.4\blender.exe',
        'C:\Program Files\Blender Foundation\Blender 4.3\blender.exe',
        'C:\Program Files\Blender Foundation\Blender 4.2\blender.exe'
    )

    $where = Get-Command blender.exe -ErrorAction SilentlyContinue
    if ($where) { $candidates += $where.Source }

    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            $label = ''
            try { $label = (& $candidate --version 2>$null | Select-Object -First 1) } catch { }
            if (-not $label) { $label = [System.IO.Path]::GetFileName($candidate) }
            return [pscustomobject]@{ Ok = $true; Label = $label; Path = $candidate }
        }
    }
    return [pscustomobject]@{ Ok = $false; Label = '未检测到'; Path = '' }
}

function Get-CkDotNetInfo {
    try {
        $framework = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction Stop
        $ok = [int]$framework.Release -ge 528040
        $label = if ($ok) { ".NET Framework $($framework.Version)" } else { '需要安装 .NET Framework 4.8' }
        return [pscustomobject]@{ Ok = $ok; Label = $label; Path = $framework.PSPath }
    } catch {
        return [pscustomobject]@{ Ok = $false; Label = '需要安装 .NET Framework 4.8'; Path = '' }
    }
}

function Get-CkCodeWalkerInfo {
    param([string]$RendererDir)

    $toolsRoot = Join-Path $RendererDir 'tools'
    $ytd = Join-Path $toolsRoot 'YtdTools.exe'
    $rpf = Join-Path $toolsRoot 'RpfTools.exe'
    $ok = (Test-Path -LiteralPath $ytd -PathType Leaf) -and (Test-Path -LiteralPath $rpf -PathType Leaf)
    return [pscustomobject]@{
        Ok = $ok
        Label = $(if ($ok) { '组件自带，已就绪' } else { '随模型组件安装' })
        Path = $toolsRoot
        YtdTool = $(if ($ok) { $ytd } else { '' })
        RpfTool = $(if ($ok) { $rpf } else { '' })
    }
}

function Get-CkSollumzInfo {
    param([string]$RendererDir)

    $path = Join-Path $RendererDir 'Sollumz'
    $ok = Test-Path -LiteralPath (Join-Path $path '__init__.py') -PathType Leaf
    return [pscustomobject]@{
        Ok = $ok
        Label = $(if ($ok) { '组件自带，已就绪' } else { '随模型组件安装' })
        Path = $(if ($ok) { $path } else { '' })
    }
}

function Get-CkMemoryGb {
    try {
        return [Math]::Round((Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).TotalPhysicalMemory / 1GB)
    } catch {
        return $null
    }
}

function Get-CkToolboxEnvironment {
    param([Parameter(Mandatory)]$Context)

    $rendererDir = $Context.Paths.RendererDir
    $settings = Get-CkDependencySettings
    $blender = Get-CkBlenderInfo -WorkspaceRoot $Context.Paths.WorkspaceRoot -Settings $settings
    $dotnet = Get-CkDotNetInfo
    $codewalker = Get-CkCodeWalkerInfo -RendererDir $rendererDir
    $sollumz = Get-CkSollumzInfo -RendererDir $rendererDir
    $rendererOk = Test-Path -LiteralPath $Context.Paths.RenderScript
    $rendererLabel = if ($rendererOk) { '已安装' } else { '未找到脚本' }
    $componentManifest = Join-Path $rendererDir '.ck-component.json'
    if ($rendererOk -and (Test-Path -LiteralPath $componentManifest -PathType Leaf)) {
        try {
            $componentInfo = Get-Content -LiteralPath $componentManifest -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($componentInfo.releaseTag) { $rendererLabel = [string]$componentInfo.releaseTag }
        } catch { }
    }
    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    $workers = [Math]::Max(1, [Math]::Min(4, [int]([Environment]::ProcessorCount / 2)))

    return [pscustomobject]@{
        Blender = $blender
        DotNet = $dotnet
        CodeWalker = $codewalker
        Sollumz = $sollumz
        Renderer = [pscustomobject]@{ Ok = $rendererOk; Label = $rendererLabel }
        CpuName = $(if ($cpu) { $cpu.Name } else { "$([Environment]::ProcessorCount) 线程 CPU" })
        MemoryGb = Get-CkMemoryGb
        RecommendedWorkers = $workers
        AllOk = ($blender.Ok -and $dotnet.Ok -and $codewalker.Ok -and $sollumz.Ok -and $rendererOk)
    }
}

Export-ModuleMember -Function Get-CkToolboxEnvironment, Get-CkDependencySettings, Set-CkDependencyPath
