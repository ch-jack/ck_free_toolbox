using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyVersion("1.0.2.0")]
[assembly: AssemblyFileVersion("1.0.2.0")]

namespace CKFreeToolbox
{
    internal static class Program
    {
        private const string AppTitle = "CK免费工具箱";
        private const string ChildArgument = "--ck-random-host";
        private const string WaitArgument = "--ck-wait";
        private const string SmokeTestArgument = "-SmokeTest";
        private const string LauncherPidVariable = "CK_TOOLBOX_LAUNCHER_PID";
        private const string WindowTitleVariable = "CK_TOOLBOX_WINDOW_TITLE";
        private const string HostDirectoryName = "process-hosts";
        private const int RandomNameBytes = 16;

        [STAThread]
        private static int Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            try
            {
                Thread.CurrentThread.CurrentUICulture = System.Globalization.CultureInfo.GetCultureInfo("zh-CN");
                Thread.CurrentThread.CurrentCulture = System.Globalization.CultureInfo.GetCultureInfo("zh-CN");

                ChildLaunch childLaunch;
                if (TryParseChildLaunch(args, out childLaunch))
                {
                    return RunRandomHost(childLaunch);
                }

                var root = GetCurrentInstallRoot();
                return StartRandomHost(root, args ?? new string[0]);
            }
            catch (Exception ex)
            {
                ShowError(ex.ToString());
                return 1;
            }
        }

        private static string GetCurrentInstallRoot()
        {
            var executablePath = Assembly.GetExecutingAssembly().Location;
            var root = Path.GetDirectoryName(executablePath);
            if (string.IsNullOrWhiteSpace(root))
            {
                root = AppDomain.CurrentDomain.BaseDirectory;
            }

            root = Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            var scriptPath = Path.Combine(root, "CKFreeToolbox.ps1");
            if (!File.Exists(scriptPath))
            {
                throw new FileNotFoundException("找不到主程序脚本：" + Environment.NewLine + scriptPath, scriptPath);
            }

            return root;
        }

        private static bool TryParseChildLaunch(string[] args, out ChildLaunch launch)
        {
            launch = null;
            if (args == null || args.Length < 2 ||
                !string.Equals(args[0], ChildArgument, StringComparison.Ordinal))
            {
                return false;
            }

            var root = args[1];
            if (string.IsNullOrWhiteSpace(root))
            {
                throw new ArgumentException("随机启动器缺少安装目录。", ChildArgument);
            }

            launch = new ChildLaunch
            {
                InstallRoot = Path.GetFullPath(root),
                UserArguments = args.Skip(2).ToArray()
            };
            return true;
        }

        private static int StartRandomHost(string root, string[] args)
        {
            string[] userArguments;
            RemoveWaitArgument(args, out userArguments);
            var hostPath = CreateHostPath();
            var hostCopied = false;

            try
            {
                var sourcePath = Assembly.GetExecutingAssembly().Location;
                File.Copy(sourcePath, hostPath, false);
                hostCopied = true;

                var childArguments = new List<string>
                {
                    ChildArgument,
                    root
                };
                childArguments.AddRange(userArguments);

                var startInfo = new ProcessStartInfo
                {
                    FileName = hostPath,
                    Arguments = BuildProcessArguments(childArguments),
                    WorkingDirectory = root,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                startInfo.EnvironmentVariables[LauncherPidVariable] =
                    Process.GetCurrentProcess().Id.ToString(System.Globalization.CultureInfo.InvariantCulture);
                startInfo.EnvironmentVariables[WindowTitleVariable] = RandomHex(RandomNameBytes);

                using (var child = Process.Start(startInfo))
                {
                    if (ShouldWaitForChild(args))
                    {
                        child.WaitForExit();
                        return child.ExitCode;
                    }

                    return 0;
                }
            }
            finally
            {
                if (hostCopied)
                {
                    TryDeleteHostFile(hostPath);
                }
            }
        }

        private static int RunRandomHost(ChildLaunch launch)
        {
            try
            {
                return RunPowerShell(launch.InstallRoot, launch.UserArguments);
            }
            finally
            {
                ScheduleHostFileCleanup(Assembly.GetExecutingAssembly().Location);
            }
        }

        private static int RunPowerShell(string root, string[] args)
        {
            root = Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            var scriptPath = Path.Combine(root, "CKFreeToolbox.ps1");
            if (!File.Exists(scriptPath))
            {
                ShowError("找不到主程序脚本：" + Environment.NewLine + scriptPath);
                return 2;
            }

            using (var runspace = RunspaceFactory.CreateRunspace())
            {
                runspace.ApartmentState = ApartmentState.STA;
                runspace.ThreadOptions = PSThreadOptions.UseCurrentThread;
                runspace.Open();

                using (var powerShell = PowerShell.Create())
                {
                    powerShell.Runspace = runspace;
                    var command = BuildCommand(root, scriptPath, args);
                    powerShell.AddScript(command);
                    powerShell.Invoke();

                    if (powerShell.Streams.Error.Count > 0)
                    {
                        ShowError(string.Join(Environment.NewLine, powerShell.Streams.Error.Select(error => error.ToString())));
                        return 1;
                    }
                }
            }

            return 0;
        }

        private static void RemoveWaitArgument(string[] args, out string[] userArguments)
        {
            var filtered = new List<string>();
            foreach (var arg in args ?? new string[0])
            {
                if (string.Equals(arg, WaitArgument, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }
                else
                {
                    filtered.Add(arg);
                }
            }

            userArguments = filtered.ToArray();
        }

        private static bool ShouldWaitForChild(string[] args)
        {
            foreach (var arg in args ?? new string[0])
            {
                if (string.Equals(arg, WaitArgument, StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(arg, SmokeTestArgument, StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }

            return false;
        }

        private static void ScheduleHostFileCleanup(string hostPath)
        {
            try
            {
                var escapedHostPath = hostPath.Replace("'", "''");
                var command = "$ErrorActionPreference = 'SilentlyContinue'; " +
                    "Start-Sleep -Milliseconds 500; " +
                    "Remove-Item -LiteralPath '" + escapedHostPath + "' -Force -ErrorAction SilentlyContinue";
                var powershellPath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.System),
                    "WindowsPowerShell",
                    "v1.0",
                    "powershell.exe");
                var startInfo = new ProcessStartInfo
                {
                    FileName = powershellPath,
                    Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command " + ProcessArgumentQuote(command),
                    WorkingDirectory = Path.GetDirectoryName(hostPath),
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    WindowStyle = ProcessWindowStyle.Hidden
                };
                var cleanupProcess = Process.Start(startInfo);
                if (cleanupProcess != null)
                {
                    cleanupProcess.Dispose();
                }
            }
            catch
            {
                // Cleanup is best-effort; the host file is safe to remove on the next launch.
            }
        }

        private static string GetHostRoot()
        {
            var localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            if (string.IsNullOrWhiteSpace(localAppData))
            {
                localAppData = Path.GetTempPath();
            }

            return Path.Combine(localAppData, "CKFreeToolbox", HostDirectoryName);
        }

        private static string CreateHostPath()
        {
            var hostRoot = GetHostRoot();
            Directory.CreateDirectory(hostRoot);
            return Path.Combine(hostRoot, RandomHex(RandomNameBytes) + ".exe");
        }

        private static void TryDeleteHostFile(string hostPath)
        {
            try
            {
                if (File.Exists(hostPath))
                {
                    File.Delete(hostPath);
                }
            }
            catch
            {
                // The executable may still be held by Windows after an abnormal exit.
            }
        }

        private static string RandomHex(int byteCount)
        {
            var bytes = new byte[byteCount];
            using (var generator = RandomNumberGenerator.Create())
            {
                generator.GetBytes(bytes);
            }

            const string alphabet = "0123456789abcdef";
            var characters = new char[byteCount * 2];
            for (var index = 0; index < bytes.Length; index++)
            {
                characters[index * 2] = alphabet[bytes[index] >> 4];
                characters[index * 2 + 1] = alphabet[bytes[index] & 0x0F];
            }

            return new string(characters);
        }

        private static string BuildCommand(string root, string scriptPath, string[] args)
        {
            var builder = new StringBuilder();
            builder.Append("$ErrorActionPreference = 'Stop'; ");
            builder.Append("Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; ");
            builder.Append("Set-Location -LiteralPath ");
            builder.Append(PowerShellQuote(root));
            builder.Append("; & ");
            builder.Append(PowerShellQuote(scriptPath));

            foreach (var arg in args ?? new string[0])
            {
                builder.Append(' ');
                builder.Append(PowerShellQuote(arg));
            }

            return builder.ToString();
        }

        private static string BuildProcessArguments(IEnumerable<string> args)
        {
            var builder = new StringBuilder();
            foreach (var arg in args ?? new string[0])
            {
                if (builder.Length > 0)
                {
                    builder.Append(' ');
                }
                builder.Append(ProcessArgumentQuote(arg));
            }

            return builder.ToString();
        }

        private static string ProcessArgumentQuote(string value)
        {
            value = value ?? string.Empty;
            var builder = new StringBuilder();
            builder.Append('"');
            var backslashes = 0;
            foreach (var character in value)
            {
                if (character == '\\')
                {
                    backslashes++;
                    continue;
                }

                if (character == '"')
                {
                    builder.Append('\\', backslashes * 2 + 1);
                    builder.Append('"');
                    backslashes = 0;
                    continue;
                }

                builder.Append('\\', backslashes);
                builder.Append(character);
                backslashes = 0;
            }

            builder.Append('\\', backslashes * 2);
            builder.Append('"');
            return builder.ToString();
        }

        private static string PowerShellQuote(string value)
        {
            return "'" + (value ?? string.Empty).Replace("'", "''") + "'";
        }

        private static void ShowError(string message)
        {
            MessageBox.Show(
                message,
                AppTitle,
                MessageBoxButtons.OK,
                MessageBoxIcon.Error
            );
        }

        private sealed class ChildLaunch
        {
            public string InstallRoot { get; set; }
            public string[] UserArguments { get; set; }
        }
    }
}
