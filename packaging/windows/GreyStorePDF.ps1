# Starts the local GreyStore PDF server (once) and opens it in the default browser.
# User data (settings, logs) lives in %LOCALAPPDATA%\GreyStorePDF because Program Files is read-only.
# The server binds to 127.0.0.1 only, so other machines on the network cannot reach it.

$ErrorActionPreference = 'Stop'

$AppDir  = $PSScriptRoot
$DataDir = Join-Path $env:LOCALAPPDATA 'GreyStorePDF'
$PidFile = Join-Path $DataDir 'server.pid'
$Port    = 8787 # must match Cerrar-GreyStorePDF.ps1
$Url     = "http://127.0.0.1:$Port"
$StartupTimeoutSeconds = 180

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

function Test-Server {
    try {
        $response = Invoke-WebRequest -Uri "$Url/api/v1/info/status" -UseBasicParsing -TimeoutSec 2
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Show-Error([string]$message) {
    [System.Windows.Forms.MessageBox]::Show($message, 'GreyStore PDF', 'OK', 'Error') | Out-Null
}

function New-SplashForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'GreyStore PDF'
    $form.Size = New-Object System.Drawing.Size(360, 130)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.ControlBox = $false
    $form.TopMost = $true
    $iconPath = Join-Path $AppDir 'GreyStorePDF.ico'
    if (Test-Path $iconPath) { $form.Icon = New-Object System.Drawing.Icon($iconPath) }

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Iniciando GreyStore PDF...`nLa primera vez puede tardar hasta un minuto."
    $label.AutoSize = $false
    $label.Dock = 'Fill'
    $label.TextAlign = 'MiddleCenter'
    $label.Font = New-Object System.Drawing.Font('Segoe UI', 10)
    $form.Controls.Add($label)
    return $form
}

New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

if (Test-Server) {
    Start-Process $Url
    exit 0
}

$splash = New-SplashForm
$splash.Show()
[System.Windows.Forms.Application]::DoEvents()

$javaw = Join-Path $AppDir 'runtime\bin\javaw.exe'
$jar   = Join-Path $AppDir 'GreyStorePDF.jar'
$javaArgs = @(
    '-Djava.net.preferIPv4Stack=true',
    "-Dstirling.base-path=`"$DataDir`"",
    "-Dserver.port=$Port",
    '-Dserver.address=127.0.0.1',
    '-DBROWSER_OPEN=false',
    '-jar', "`"$jar`""
)

$env:DISABLE_ADDITIONAL_FEATURES = 'true'
$env:STIRLING_BASE_PATH = $DataDir

try {
    $process = Start-Process -FilePath $javaw -ArgumentList $javaArgs -WorkingDirectory $DataDir -PassThru
} catch {
    $splash.Close()
    Show-Error "No se pudo iniciar GreyStore PDF.`n`n$($_.Exception.Message)"
    exit 1
}
Set-Content -Path $PidFile -Value $process.Id

$deadline = (Get-Date).AddSeconds($StartupTimeoutSeconds)
while ((Get-Date) -lt $deadline) {
    if ($process.HasExited) {
        $splash.Close()
        Remove-Item $PidFile -ErrorAction SilentlyContinue
        Show-Error "GreyStore PDF se cerró al iniciar.`n`nRevisa los registros en:`n$(Join-Path $DataDir 'logs')`n`nSi otro programa usa el puerto $Port, ciérralo e intenta de nuevo."
        exit 1
    }
    if (Test-Server) {
        $splash.Close()
        Start-Process $Url
        exit 0
    }
    for ($i = 0; $i -lt 5; $i++) {
        Start-Sleep -Milliseconds 100
        [System.Windows.Forms.Application]::DoEvents()
    }
}

$splash.Close()
Show-Error "GreyStore PDF está tardando demasiado en iniciar.`n`nRevisa los registros en:`n$(Join-Path $DataDir 'logs')"
exit 1
