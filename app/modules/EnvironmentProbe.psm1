function Get-CkBlenderInfo {
    param([string]$WorkspaceRoot)

    $candidates = @()

    foreach ($envName in @('BLENDER_EXE', 'BLENDER_PATH')) {
        $value = [Environment]::GetEnvironmentVariable($envName)
        if ($value) { $candidates += $value }
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
        $label = if ($ok) { ".NET Framework $($framework.Version)" } else { '需要 .NET Framework 4.8' }
        return [pscustomobject]@{ Ok = $ok; Label = $label; Path = $framework.PSPath }
    } catch {
        return [pscustomobject]@{ Ok = $false; Label = '需要 .NET Framework 4.8'; Path = '' }
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
    $blender = Get-CkBlenderInfo -WorkspaceRoot $Context.Paths.WorkspaceRoot
    $dotnet = Get-CkDotNetInfo
    $codewalkerOk = (Test-Path -LiteralPath (Join-Path $rendererDir 'tools\YtdTools.exe')) -and (Test-Path -LiteralPath (Join-Path $rendererDir 'tools\RpfTools.exe'))
    $sollumzOk = Test-Path -LiteralPath (Join-Path $rendererDir 'Sollumz\__init__.py')
    $rendererOk = Test-Path -LiteralPath $Context.Paths.RenderScript
    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    $workers = [Math]::Max(1, [Math]::Min(4, [int]([Environment]::ProcessorCount / 2)))

    return [pscustomobject]@{
        Blender = $blender
        DotNet = $dotnet
        CodeWalker = [pscustomobject]@{ Ok = $codewalkerOk; Label = $(if ($codewalkerOk) { '已安装' } else { '缺少工具文件' }) }
        Sollumz = [pscustomobject]@{ Ok = $sollumzOk; Label = $(if ($sollumzOk) { '已安装' } else { '未检测到' }) }
        Renderer = [pscustomobject]@{ Ok = $rendererOk; Label = $(if ($rendererOk) { 'v1.0.1' } else { '未找到脚本' }) }
        CpuName = $(if ($cpu) { $cpu.Name } else { "$([Environment]::ProcessorCount) 线程 CPU" })
        MemoryGb = Get-CkMemoryGb
        RecommendedWorkers = $workers
        AllOk = ($blender.Ok -and $dotnet.Ok -and $codewalkerOk -and $sollumzOk -and $rendererOk)
    }
}

Export-ModuleMember -Function Get-CkToolboxEnvironment
