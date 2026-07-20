function Set-CkDependencyPath {
    param(
        [Parameter(Mandatory)][ValidateSet('Blender', 'Python', 'Java')][string]$Dependency,
        [Parameter(Mandatory)][string]$Path
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $fullPath)) { throw "选择的路径不存在: $fullPath" }
    $fileName = if ($Dependency -eq 'Blender') {
        'blender.exe'
    } elseif ($Dependency -eq 'Python') {
        'python.exe'
    } else {
        'java.exe'
    }
    $resolved = Find-CkDependencyFile -Root $fullPath -FileName $fileName
    if (-not $resolved) { throw ("选择的位置没有找到 {0}: {1}" -f $fileName, $fullPath) }
    return Set-CkToolboxDependencyPath -Dependency $Dependency -Path $resolved
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

    $minimumVersion = [version]'4.2.0'
    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            $label = ''
            try { $label = (& $candidate --version 2>$null | Select-Object -First 1) } catch { }
            if (-not $label) {
                return [pscustomobject]@{
                    Ok = $false
                    Label = '无法识别 Blender 版本'
                    Path = $candidate
                }
            }

            $detectedVersion = $null
            if ($label -match '(?i)\bBlender\s+(\d+\.\d+(?:\.\d+)?)') {
                try { $detectedVersion = [version]$Matches[1] } catch { }
            }
            if (-not $detectedVersion) {
                return [pscustomobject]@{
                    Ok = $false
                    Label = "$label（无法识别版本）"
                    Path = $candidate
                }
            }

            $supported = $detectedVersion -ge $minimumVersion
            return [pscustomobject]@{
                Ok = $supported
                Label = $(if ($supported) { $label } else { "$label（需要 4.2 或更高版本，推荐 5.1）" })
                Path = $candidate
                Version = $detectedVersion.ToString()
            }
        }
    }
    return [pscustomobject]@{ Ok = $false; Label = '未检测到'; Path = '' }
}


function Test-CkJavaExecutable {
    param([Parameter(Mandatory)][string]$Path)

    $resolved = Find-CkDependencyFile -Root $Path -FileName 'java.exe'
    if (-not $resolved) {
        return [pscustomobject]@{
            Ok = $false
            Label = '未找到 java.exe'
            Path = ''
            Version = ''
            Major = 0
            Reason = "选择的位置中没有找到 java.exe: $Path"
        }
    }

    $process = $null
    try {
        $psi = New-Object Diagnostics.ProcessStartInfo
        $psi.FileName = $resolved
        $psi.Arguments = '-version'
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
        if (-not $process.Start()) { throw 'Java 版本检测进程未启动。' }
        if (-not $process.WaitForExit(8000)) {
            try { $process.Kill() } catch { }
            return [pscustomobject]@{
                Ok = $false
                Label = 'Java 检测超时'
                Path = $resolved
                Version = ''
                Major = 0
                Reason = 'java -version 超过 8 秒没有返回。'
            }
        }

        $stderr = $process.StandardError.ReadToEnd()
        $stdout = $process.StandardOutput.ReadToEnd()
        $versionText = (($stderr, $stdout) -join [Environment]::NewLine).Trim()
        $firstLine = [string]@($versionText -split '\r?\n' | Where-Object { $_.Trim() } | Select-Object -First 1)
        if ($process.ExitCode -ne 0) {
            $detail = if ($firstLine) { $firstLine } else { "退出码 $($process.ExitCode)" }
            return [pscustomobject]@{
                Ok = $false
                Label = 'Java 无法运行'
                Path = $resolved
                Version = ''
                Major = 0
                Reason = "java -version 执行失败: $detail"
            }
        }

        $major = 0
        if ($versionText -match '(?im)\bversion\s+"?(\d+)(?:\.(\d+))?') {
            $first = [int]$Matches[1]
            $second = if ($Matches[2]) { [int]$Matches[2] } else { 0 }
            $major = if ($first -eq 1) { $second } else { $first }
        } elseif ($versionText -match '(?im)\b(?:openjdk|java)\s+"?(\d+)(?:\.(\d+))?') {
            $first = [int]$Matches[1]
            $second = if ($Matches[2]) { [int]$Matches[2] } else { 0 }
            $major = if ($first -eq 1) { $second } else { $first }
        }

        if ($major -lt 1) {
            return [pscustomobject]@{
                Ok = $false
                Label = '无法识别 Java 版本'
                Path = $resolved
                Version = $firstLine
                Major = 0
                Reason = "无法从 java -version 识别版本: $firstLine"
            }
        }

        $ok = $major -ge 8
        return [pscustomobject]@{
            Ok = $ok
            Label = $(if ($ok) { "Java $major 已就绪" } else { "Java $major 版本过低" })
            Path = $resolved
            Version = $firstLine
            Major = $major
            Reason = $(if ($ok) { '' } else { "需要 Java 8 或更高版本，推荐 Java 17。当前: $firstLine" })
        }
    } catch {
        return [pscustomobject]@{
            Ok = $false
            Label = 'Java 检测失败'
            Path = $resolved
            Version = ''
            Major = 0
            Reason = $_.Exception.Message
        }
    } finally {
        if ($process) { $process.Dispose() }
    }
}

function Get-CkJavaInfo {
    param($Settings)

    if (-not $Settings) { $Settings = Get-CkDependencySettings }
    $candidates = @()
    if ($Settings.JavaPath) { $candidates += [string]$Settings.JavaPath }

    foreach ($scope in @('Process', 'User', 'Machine')) {
        try {
            $javaHome = [Environment]::GetEnvironmentVariable('JAVA_HOME', $scope)
            if ($javaHome) { $candidates += $javaHome }
        } catch { }
    }

    $where = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($where -and $where.Source) { $candidates += [string]$where.Source }

    foreach ($keyPath in @(
        'HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment',
        'HKLM:\SOFTWARE\JavaSoft\JDK',
        'HKLM:\SOFTWARE\WOW6432Node\JavaSoft\Java Runtime Environment',
        'HKLM:\SOFTWARE\WOW6432Node\JavaSoft\JDK'
    )) {
        try {
            $key = Get-ItemProperty -LiteralPath $keyPath -ErrorAction Stop
            if ($key.CurrentVersion) {
                $versionKey = Join-Path $keyPath ([string]$key.CurrentVersion)
                $version = Get-ItemProperty -LiteralPath $versionKey -ErrorAction Stop
                if ($version.JavaHome) { $candidates += [string]$version.JavaHome }
            }
        } catch { }
    }

    $programRoots = @(
        [Environment]::GetFolderPath('ProgramFiles'),
        [Environment]::GetFolderPath('ProgramFilesX86')
    ) | Where-Object { $_ } | Select-Object -Unique

    foreach ($programRoot in $programRoots) {
        foreach ($vendor in @('Eclipse Adoptium', 'Java', 'Amazon Corretto', 'Zulu', 'BellSoft')) {
            $vendorRoot = Join-Path $programRoot $vendor
            if (Test-Path -LiteralPath $vendorRoot -PathType Container) { $candidates += $vendorRoot }
        }
        $microsoftRoot = Join-Path $programRoot 'Microsoft'
        if (Test-Path -LiteralPath $microsoftRoot -PathType Container) {
            $candidates += @(Get-ChildItem -LiteralPath $microsoftRoot -Directory -Filter 'jdk-*' -ErrorAction SilentlyContinue |
                Sort-Object Name -Descending |
                ForEach-Object { $_.FullName })
        }
    }

    $firstFailure = $null
    foreach ($candidate in @($candidates | Where-Object { $_ } | Select-Object -Unique)) {
        $info = Test-CkJavaExecutable -Path ([string]$candidate)
        if ($info.Ok) { return $info }
        if (-not $firstFailure) { $firstFailure = $info }
    }
    if ($firstFailure) { return $firstFailure }

    return [pscustomobject]@{
        Ok = $false
        Label = '未检测到 Java'
        Path = ''
        Version = ''
        Major = 0
        Reason = '未检测到 Java 8 或更高版本。推荐安装 Java 17，或手动选择 Java 安装目录。'
    }
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

Export-ModuleMember -Function Get-CkToolboxEnvironment, Set-CkDependencyPath, Get-CkJavaInfo, Test-CkJavaExecutable
