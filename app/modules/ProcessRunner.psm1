function Test-CkPythonExecutable {
    param(
        [Parameter(Mandatory)][string]$Path,
        [version]$MinimumVersion = [version]'3.7.0'
    )

    $fullPath = ''
    try { $fullPath = [IO.Path]::GetFullPath($Path) } catch {
        return [pscustomobject]@{ Ok = $false; Path = [string]$Path; Version = ''; Label = '路径无效'; Reason = $_.Exception.Message }
    }
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        return [pscustomobject]@{ Ok = $false; Path = $fullPath; Version = ''; Label = '文件不存在'; Reason = "Python 不存在: $fullPath" }
    }

    $file = Get-Item -LiteralPath $fullPath -ErrorAction SilentlyContinue
    if (-not $file -or $file.Length -le 0 -or $fullPath -match '(?i)\\WindowsApps\\python(?:3)?\.exe$') {
        return [pscustomobject]@{
            Ok = $false
            Path = $fullPath
            Version = ''
            Label = 'Windows 商店占位程序'
            Reason = '检测到 WindowsApps 的 Python 商店别名，不是真实 Python。'
        }
    }

    $process = $null
    try {
        $psi = New-Object Diagnostics.ProcessStartInfo
        $psi.FileName = $fullPath
        $psi.Arguments = '-c "import sys; print(''%d.%d.%d'' % sys.version_info[:3])"'
        $psi.WorkingDirectory = Split-Path -Parent $fullPath
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
        if (-not $process.Start()) { throw '进程未启动。' }
        if (-not $process.WaitForExit(8000)) {
            try { $process.Kill() } catch { }
            return [pscustomobject]@{ Ok = $false; Path = $fullPath; Version = ''; Label = '检测超时'; Reason = 'Python 版本检测超过 8 秒。' }
        }
        $stdout = $process.StandardOutput.ReadToEnd().Trim()
        $stderr = $process.StandardError.ReadToEnd().Trim()
        if ($process.ExitCode -ne 0) {
            $detail = if ($stderr) { $stderr } else { "退出码 $($process.ExitCode)" }
            return [pscustomobject]@{ Ok = $false; Path = $fullPath; Version = ''; Label = '无法运行'; Reason = "Python 无法运行: $detail" }
        }
        if ($stdout -notmatch '^(?<version>\d+\.\d+\.\d+)$') {
            return [pscustomobject]@{ Ok = $false; Path = $fullPath; Version = ''; Label = '版本无法识别'; Reason = "Python 返回了无效版本: $stdout" }
        }

        $version = [version]$Matches.version
        $ok = $version -ge $MinimumVersion
        return [pscustomobject]@{
            Ok = $ok
            Path = $fullPath
            Version = $version.ToString()
            Label = $(if ($ok) { "Python $version" } else { "Python $version（需要 $MinimumVersion 或更高版本）" })
            Reason = $(if ($ok) { '' } else { "Python 版本过低: $version，最低需要 $MinimumVersion。" })
        }
    } catch {
        return [pscustomobject]@{ Ok = $false; Path = $fullPath; Version = ''; Label = '无法启动'; Reason = $_.Exception.Message }
    } finally {
        if ($process) { $process.Dispose() }
    }
}

function Get-CkPythonInfo {
    param(
        [string]$RuntimeRoot,
        [string]$BlenderExe,
        [string]$ConfiguredPath,
        [switch]$PreferBlender
    )

    $candidates = New-Object System.Collections.Generic.List[string]
    $blenderCandidates = New-Object System.Collections.Generic.List[string]
    if ($BlenderExe -and (Test-Path -LiteralPath $BlenderExe -PathType Leaf)) {
        $blenderRoot = Split-Path -Parent $BlenderExe
        foreach ($versionDir in @(Get-ChildItem -LiteralPath $blenderRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
            $blenderCandidates.Add((Join-Path $versionDir.FullName 'python\bin\python.exe'))
        }
    }
    if ($PreferBlender) {
        foreach ($candidate in $blenderCandidates) { $candidates.Add($candidate) }
    }
    if ($ConfiguredPath) { $candidates.Add($ConfiguredPath) }
    if ($RuntimeRoot) { $candidates.Add((Join-Path $RuntimeRoot 'python\python.exe')) }

    foreach ($commandName in @('python.exe', 'py.exe')) {
        foreach ($command in @(Get-Command $commandName -All -ErrorAction SilentlyContinue)) {
            if ($command.Source) { $candidates.Add([string]$command.Source) }
        }
    }

    $localPythonRoot = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Programs\Python'
    if (Test-Path -LiteralPath $localPythonRoot -PathType Container) {
        foreach ($directory in @(Get-ChildItem -LiteralPath $localPythonRoot -Directory -Filter 'Python*' -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
            $candidates.Add((Join-Path $directory.FullName 'python.exe'))
        }
    }

    if (-not $PreferBlender) {
        foreach ($candidate in $blenderCandidates) { $candidates.Add($candidate) }
    }

    $firstFailure = $null
    foreach ($candidate in @($candidates | Where-Object { $_ } | Select-Object -Unique)) {
        $result = Test-CkPythonExecutable -Path $candidate
        if ($result.Ok) { return $result }
        if (-not $firstFailure) { $firstFailure = $result }
    }

    $detail = if ($firstFailure -and $firstFailure.Reason) { " $($firstFailure.Reason)" } else { '' }
    return [pscustomobject]@{
        Ok = $false
        Path = ''
        Version = ''
        Label = '未检测到 Python 3.7+'
        Reason = "未检测到可用的 Python 3.7+。请从 Python 官网安装后选择 python.exe。$detail"
    }
}

function Get-CkPythonExe {
    param(
        [string]$RuntimeRoot,
        [string]$BlenderExe,
        [string]$ConfiguredPath,
        [switch]$PreferBlender
    )

    $info = Get-CkPythonInfo -RuntimeRoot $RuntimeRoot -BlenderExe $BlenderExe -ConfiguredPath $ConfiguredPath -PreferBlender:$PreferBlender
    if (-not $info.Ok) { throw [string]$info.Reason }
    return [string]$info.Path
}
if (-not ([System.Management.Automation.PSTypeName]'CKFreeToolbox.Runtime.ProcessOutputBuffer').Type) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Text;

namespace CKFreeToolbox.Runtime
{
    public sealed class ProcessOutputBuffer
    {
        private readonly ConcurrentQueue<string> lines = new ConcurrentQueue<string>();

        public void Attach(Process process)
        {
            process.OutputDataReceived += delegate(object sender, DataReceivedEventArgs args)
            {
                if (args.Data != null) lines.Enqueue(args.Data);
            };
            process.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs args)
            {
                if (args.Data != null) lines.Enqueue(args.Data);
            };
        }

        public bool TryDequeue(out string line)
        {
            return lines.TryDequeue(out line);
        }
    }

    public static class CommandLine
    {
        public static string Quote(string value)
        {
            value = value ?? string.Empty;
            if (value.Length == 0) return "\"\"";
            if (value.IndexOfAny(new[] { ' ', '\t', '\n', '\v', '"' }) < 0) return value;

            var result = new StringBuilder();
            result.Append('"');
            var backslashes = 0;

            foreach (var character in value)
            {
                if (character == '\\')
                {
                    backslashes++;
                }
                else if (character == '"')
                {
                    result.Append('\\', (backslashes * 2) + 1);
                    result.Append('"');
                    backslashes = 0;
                }
                else
                {
                    result.Append('\\', backslashes);
                    result.Append(character);
                    backslashes = 0;
                }
            }

            result.Append('\\', backslashes * 2);
            result.Append('"');
            return result.ToString();
        }
    }
}
'@
}

function Join-CkArgumentList {
    param([Parameter(Mandatory)][object[]]$Arguments)

    return ($Arguments | ForEach-Object {
        [CKFreeToolbox.Runtime.CommandLine]::Quote([string]$_)
    }) -join ' '
}

function Start-CkLoggedProcess {
    param(
        [Parameter(Mandatory)][string]$FileName,
        [Parameter(Mandatory)][object[]]$Arguments,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)]$Dispatcher,
        [Parameter(Mandatory)][scriptblock]$OnOutput,
        [Parameter(Mandatory)][scriptblock]$OnExit,
        [scriptblock]$OnError
    )

    if (-not (Test-Path -LiteralPath $WorkingDirectory -PathType Container)) {
        throw "工作目录不存在: $WorkingDirectory"
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FileName
    $psi.Arguments = Join-CkArgumentList -Arguments $Arguments
    $psi.WorkingDirectory = $WorkingDirectory
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.EnvironmentVariables['PYTHONUNBUFFERED'] = '1'
    $psi.EnvironmentVariables['PYTHONIOENCODING'] = 'utf-8'
    try {
        $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
        $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    } catch { }

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $buffer = New-Object CKFreeToolbox.Runtime.ProcessOutputBuffer
    $buffer.Attach($proc)

    try {
        if (-not $proc.Start()) {
            throw "无法启动进程: $FileName"
        }
        $proc.BeginOutputReadLine()
        $proc.BeginErrorReadLine()
    } catch {
        $proc.Dispose()
        throw
    }

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(100)
    $exitHandled = $false
    $callbackErrorReported = $false
    $runtimeState = [pscustomobject]@{ LastCallbackError = '' }

    $drainOutput = {
        $line = $null
        while ($buffer.TryDequeue([ref]$line)) {
            & $OnOutput $line
            $line = $null
        }
    }.GetNewClosure()

    $tick = {
        try {
            & $drainOutput

            if (-not $exitHandled -and $proc.HasExited) {
                $proc.WaitForExit()
                & $drainOutput
                $exitHandled = $true
                $timer.Stop()
                & $OnExit $proc.ExitCode
            }
        } catch {
            if (-not $callbackErrorReported) {
                $message = $_.Exception.Message
                $callbackErrorReported = $true
                $runtimeState.LastCallbackError = $message
                if ($OnError) {
                    try { & $OnError $message } catch { }
                }
            }
        }
    }.GetNewClosure()

    $timer.Add_Tick($tick)
    $timer.Start()

    return [pscustomobject]@{
        Process = $proc
        Timer = $timer
        OutputBuffer = $buffer
        RuntimeState = $runtimeState
    }
}

Export-ModuleMember -Function Test-CkPythonExecutable, Get-CkPythonInfo, Get-CkPythonExe, Join-CkArgumentList, Start-CkLoggedProcess
