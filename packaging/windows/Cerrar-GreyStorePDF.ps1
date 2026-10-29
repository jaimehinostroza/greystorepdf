# Stops the local GreyStore PDF server started by GreyStorePDF.ps1.
# Pass -Quiet to skip the confirmation dialog (used by the uninstaller).

param([switch]$Quiet)

$DataDir = Join-Path $env:LOCALAPPDATA 'GreyStorePDF'
$PidFile = Join-Path $DataDir 'server.pid'
$Port    = 8787 # must match GreyStorePDF.ps1

$stopped = $false

if (Test-Path $PidFile) {
    $serverPid = Get-Content $PidFile -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($serverPid) {
        # The PID may have been reused by an unrelated program after a reboot: only stop it if it is our java.
        $process = Get-Process -Id ([int]$serverPid) -ErrorAction SilentlyContinue
        if ($process -and $process.ProcessName -like 'java*') {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            $stopped = $true
        }
    }
    Remove-Item $PidFile -ErrorAction SilentlyContinue
}

if (-not $stopped) {
    $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($listener) {
        $process = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
        if ($process -and $process.ProcessName -like 'java*') {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            $stopped = $true
        }
    }
}

if (-not $Quiet) {
    Add-Type -AssemblyName System.Windows.Forms
    $message = if ($stopped) { 'GreyStore PDF se cerró correctamente.' } else { 'GreyStore PDF no estaba en ejecución.' }
    [System.Windows.Forms.MessageBox]::Show($message, 'GreyStore PDF', 'OK', 'Information') | Out-Null
}
