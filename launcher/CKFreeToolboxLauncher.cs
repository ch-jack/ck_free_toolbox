using System;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyTitle("CK免费工具箱")]
[assembly: AssemblyDescription("CK Free Toolbox native launcher")]
[assembly: AssemblyCompany("CK")]
[assembly: AssemblyProduct("CK免费工具箱")]
[assembly: AssemblyCopyright("Copyright (c) CK")]
[assembly: AssemblyVersion("1.0.1.0")]
[assembly: AssemblyFileVersion("1.0.1.0")]

namespace CKFreeToolbox
{
    internal static class Program
    {
        private const string AppTitle = "CK免费工具箱";

        [STAThread]
        private static int Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            try
            {
                Thread.CurrentThread.CurrentUICulture = System.Globalization.CultureInfo.GetCultureInfo("zh-CN");
                Thread.CurrentThread.CurrentCulture = System.Globalization.CultureInfo.GetCultureInfo("zh-CN");

                var root = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
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
            catch (Exception ex)
            {
                ShowError(ex.ToString());
                return 1;
            }
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
    }
}