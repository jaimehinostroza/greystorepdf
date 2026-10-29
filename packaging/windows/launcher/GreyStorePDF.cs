// GreyStore PDF launcher.
//
//   GreyStorePDF.exe                  start the local server (once) and open it in the default browser
//   GreyStorePDF.exe --stop [--quiet] stop the server; --quiet skips the confirmation dialog (uninstaller)
//
// Compiled by the Windows workflow with the C# 5 compiler that ships with .NET Framework 4
// (csc.exe), so this file must stay within C# 5: no string interpolation, no ?. operator.
//
// User data (settings, logs) lives in %LOCALAPPDATA%\GreyStorePDF because the install folder may be
// read-only. The server binds to 127.0.0.1, so other machines on the network cannot reach it.

using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;

[assembly: System.Reflection.AssemblyTitle("GreyStore PDF")]
[assembly: System.Reflection.AssemblyProduct("GreyStore PDF")]
[assembly: System.Reflection.AssemblyCompany("GreyStoreChile")]
[assembly: System.Reflection.AssemblyCopyright("GreyStoreChile. Basado en Stirling-PDF (MIT).")]

static class Program
{
    const int Port = 8787;
    const int StartupTimeoutSeconds = 180;
    const string AppTitle = "GreyStore PDF";

    static readonly string Url = "http://127.0.0.1:" + Port;
    static readonly string AppDir = AppDomain.CurrentDomain.BaseDirectory;
    static readonly string DataDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "GreyStorePDF");
    static readonly string PidFile = Path.Combine(DataDir, "server.pid");
    static readonly string LogDir = Path.Combine(DataDir, "logs");

    [STAThread]
    static int Main(string[] args)
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Directory.CreateDirectory(DataDir);

        if (HasArg(args, "--stop"))
        {
            return Stop(HasArg(args, "--quiet"));
        }

        bool firstLauncher;
        using (Mutex mutex = new Mutex(true, "Local\\GreyStorePDF.Launcher", out firstLauncher))
        {
            // A second double-click while the first launcher is still waiting for the server
            // would start a second Java process on the same port; that launcher opens the browser.
            if (!firstLauncher)
            {
                return 0;
            }
            return Start();
        }
    }

    static bool HasArg(string[] args, string name)
    {
        foreach (string arg in args)
        {
            if (string.Equals(arg, name, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }
        return false;
    }

    static int Start()
    {
        if (IsServerUp())
        {
            OpenBrowser();
            return 0;
        }

        SplashForm splash = new SplashForm();
        splash.Show();
        Application.DoEvents();

        Process server;
        try
        {
            server = StartServer();
        }
        catch (Exception ex)
        {
            splash.Close();
            ShowError("No se pudo iniciar GreyStore PDF.\n\n" + ex.Message);
            return 1;
        }
        File.WriteAllText(PidFile, server.Id.ToString());

        DateTime deadline = DateTime.Now.AddSeconds(StartupTimeoutSeconds);
        while (DateTime.Now < deadline)
        {
            if (server.HasExited)
            {
                splash.Close();
                DeletePidFile();
                ShowError("GreyStore PDF se cerró al iniciar.\n\nRevisa los registros en:\n" + LogDir
                    + "\n\nSi otro programa usa el puerto " + Port + ", ciérralo e intenta de nuevo.");
                return 1;
            }
            if (IsServerUp())
            {
                splash.Close();
                OpenBrowser();
                return 0;
            }
            for (int i = 0; i < 5; i++)
            {
                Thread.Sleep(100);
                Application.DoEvents();
            }
        }

        splash.Close();
        ShowError("GreyStore PDF está tardando demasiado en iniciar.\n\nRevisa los registros en:\n" + LogDir);
        return 1;
    }

    static Process StartServer()
    {
        string javaw = Path.Combine(AppDir, Path.Combine("runtime", Path.Combine("bin", "javaw.exe")));
        string jar = Path.Combine(AppDir, "GreyStorePDF.jar");

        ProcessStartInfo info = new ProcessStartInfo(javaw);
        info.Arguments = "-Djava.net.preferIPv4Stack=true"
            + " \"-Dstirling.base-path=" + DataDir + "\""
            + " -Dserver.port=" + Port
            + " -Dserver.address=127.0.0.1"
            + " -DBROWSER_OPEN=false"
            + " -jar \"" + jar + "\"";
        info.WorkingDirectory = DataDir;
        info.UseShellExecute = false;
        info.CreateNoWindow = true;
        info.EnvironmentVariables["DISABLE_ADDITIONAL_FEATURES"] = "true";
        info.EnvironmentVariables["STIRLING_BASE_PATH"] = DataDir;
        return Process.Start(info);
    }

    static int Stop(bool quiet)
    {
        bool stopped = KillIfJava(ReadPidFile());
        DeletePidFile();
        if (!stopped)
        {
            stopped = KillIfJava(FindListeningPid(Port));
        }

        if (!quiet)
        {
            MessageBox.Show(
                stopped ? "GreyStore PDF se cerró correctamente." : "GreyStore PDF no estaba en ejecución.",
                AppTitle, MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        return 0;
    }

    // The PID file can outlive a reboot and point at an unrelated process, so only Java is stopped.
    static bool KillIfJava(int pid)
    {
        if (pid <= 0)
        {
            return false;
        }
        try
        {
            Process process = Process.GetProcessById(pid);
            if (!process.ProcessName.StartsWith("java", StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }
            process.Kill();
            process.WaitForExit(10000);
            return true;
        }
        catch (Exception)
        {
            return false;
        }
    }

    static int ReadPidFile()
    {
        try
        {
            int pid;
            return int.TryParse(File.ReadAllText(PidFile).Trim(), out pid) ? pid : 0;
        }
        catch (Exception)
        {
            return 0;
        }
    }

    static void DeletePidFile()
    {
        try
        {
            File.Delete(PidFile);
        }
        catch (Exception)
        {
        }
    }

    // .NET Framework has no API for the process that owns a socket, so netstat is parsed.
    static int FindListeningPid(int port)
    {
        try
        {
            ProcessStartInfo info = new ProcessStartInfo("netstat", "-ano -p TCP");
            info.UseShellExecute = false;
            info.RedirectStandardOutput = true;
            info.CreateNoWindow = true;
            using (Process netstat = Process.Start(info))
            {
                string output = netstat.StandardOutput.ReadToEnd();
                netstat.WaitForExit(5000);
                Match match = Regex.Match(output, @"127\.0\.0\.1:" + port + @"\s+\S+\s+\S+\s+(\d+)");
                return match.Success ? int.Parse(match.Groups[1].Value) : 0;
            }
        }
        catch (Exception)
        {
            return 0;
        }
    }

    static bool IsServerUp()
    {
        try
        {
            HttpWebRequest request = (HttpWebRequest)WebRequest.Create(Url + "/api/v1/info/status");
            request.Timeout = 2000;
            request.Proxy = null;
            using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
            {
                return response.StatusCode == HttpStatusCode.OK;
            }
        }
        catch (Exception)
        {
            return false;
        }
    }

    static void OpenBrowser()
    {
        Process.Start(new ProcessStartInfo(Url) { UseShellExecute = true });
    }

    static void ShowError(string message)
    {
        MessageBox.Show(message, AppTitle, MessageBoxButtons.OK, MessageBoxIcon.Error);
    }

    sealed class SplashForm : Form
    {
        public SplashForm()
        {
            Text = AppTitle;
            ClientSize = new Size(380, 110);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            ControlBox = false;
            TopMost = true;
            ShowInTaskbar = true;
            try
            {
                Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
            }
            catch (Exception)
            {
            }

            Label label = new Label();
            label.Text = "Iniciando GreyStore PDF...\nLa primera vez puede tardar hasta un minuto.";
            label.Dock = DockStyle.Fill;
            label.TextAlign = ContentAlignment.MiddleCenter;
            label.Font = new Font("Segoe UI", 10f);
            Controls.Add(label);
        }
    }
}
