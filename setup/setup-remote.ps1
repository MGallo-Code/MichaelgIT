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
    Write-Host "Installing SSH server (this may take a few minutes)..."
    $ProgressPreference = 'SilentlyContinue'
    $result = Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    $ProgressPreference = 'Continue'
    if ($result.RestartNeeded) {
        Write-Host "[note] A restart may be needed to finish setup." -ForegroundColor Yellow
    }
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

$existing = netsh advfirewall firewall show rule name="OpenSSH-Server-In-TCP" 2>$null
if ($existing -match "OpenSSH-Server-In-TCP") {
    Write-Ok "SSH firewall rule already exists"
}
else {
    netsh advfirewall firewall add rule name="OpenSSH-Server-In-TCP" dir=in action=allow protocol=TCP localport=22 | Out-Null
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

# ── Pause if run from a file (not piped) ────────────────────────────
if ($MyInvocation.MyCommand.Path) {
    Write-Host ""
    Read-Host "Press Enter to close this window"
}
