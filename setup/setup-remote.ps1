# MichaelGIT Remote Setup (Windows)
# Enables SSH so your technician can help remotely.
# Download from: michaelgit.com/setup

$ErrorActionPreference = "Stop"

function Write-Step { param($msg) Write-Host "`n==> $msg" -ForegroundColor Green }
function Write-Ok   { param($msg) Write-Host "[ok] $msg" -ForegroundColor Green }
function Write-Err  { param($msg) Write-Host "[error] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MichaelGIT - Remote Setup" -ForegroundColor Cyan
Write-Host "  michaelgit.com" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── Check admin ──────────────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Err "This script must be run as Administrator."
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again."
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# ── Enable OpenSSH Server ────────────────────────────────────────────
Write-Step "Setting up remote access"

$sshServer = Get-WindowsCapability -Online | Where-Object Name -like "OpenSSH.Server*"
if ($sshServer.State -eq "Installed") {
    Write-Ok "SSH server already installed"
}
else {
    Write-Host "Installing SSH server..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
    Write-Ok "SSH server installed"
}

# Start and enable SSH service
Start-Service sshd -ErrorAction SilentlyContinue
Set-Service -Name sshd -StartupType Automatic
Write-Ok "SSH service started and set to auto-start"

# Set PowerShell as default SSH shell
$regPath = "HKLM:\SOFTWARE\OpenSSH"
$psPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
New-ItemProperty -Path $regPath -Name DefaultShell -Value $psPath -PropertyType String -Force | Out-Null
Write-Ok "PowerShell set as default SSH shell"

# ── Firewall ─────────────────────────────────────────────────────────
Write-Step "Configuring firewall"

$rule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
if ($rule) {
    Write-Ok "SSH firewall rule already exists"
}
else {
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
    Write-Ok "SSH firewall rule created (port 22)"
}

# ── Gather connection info ───────────────────────────────────────────
Write-Step "Your connection info"

$lanIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*" } | Select-Object -First 1).IPAddress
$hostname = $env:COMPUTERNAME
$username = $env:USERNAME
$os = (Get-CimInstance Win32_OperatingSystem).Caption

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  TELL YOUR TECHNICIAN:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  IP Address:  $lanIp" -ForegroundColor White
Write-Host "  Username:    $username" -ForegroundColor White
Write-Host "  Computer:    $hostname" -ForegroundColor White
Write-Host "  OS:          $os" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

Write-Ok "Remote access is ready!"
Write-Host "Your technician can now connect to help you."
Write-Host ""

# ── Self-destruct ────────────────────────────────────────────────────
$scriptPath = $MyInvocation.MyCommand.Path
if ($scriptPath) {
    # Schedule deletion after script exits (can't delete while running)
    $deleteCmd = "Start-Sleep -Seconds 2; Remove-Item -Path '$scriptPath' -Force"
    Start-Process powershell -ArgumentList "-WindowStyle Hidden -Command $deleteCmd" -WindowStyle Hidden
    Write-Host "(This setup script will clean itself up automatically.)" -ForegroundColor DarkGray
}

Write-Host ""
Read-Host "Press Enter to close this window"
