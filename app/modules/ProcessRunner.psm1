function Get-CkPythonExe {
    param(
        [string]$RuntimeRoot,
        [string]$BlenderExe
    )

    $candidates = New-Object System.Collections.Generic.List[string]
    if ($RuntimeRoot) {
        $candidates.Add((Join-Path $RuntimeRoot 'python\python.exe'))
    }

    if ($BlenderExe -and (Test-Path -LiteralPath $BlenderExe -PathType Leaf)) {
        $blenderRoot = Split-Path -Parent $BlenderExe
        foreach ($versionDir in @(Get-ChildItem -LiteralPath $blenderRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
            $candidates.Add((Join-Path $versionDir.FullName 'python\bin\python.exe'))
        }
    }

    $cmd = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($cmd) { $candidates.Add($cmd.Source) }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return $candidate
        }
    }

    throw '未找到 Python 运行时。请安装官方 Blender，工具箱会自动使用 Blender 自带 Python。'
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
        throw "???????: $WorkingDirectory"
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
            throw "??????: $FileName"
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

Export-ModuleMember -Function Get-CkPythonExe, Join-CkArgumentList, Start-CkLoggedProcess
