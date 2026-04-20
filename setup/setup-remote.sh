#!/usr/bin/env bash
# MichaelGIT Remote Setup (macOS)
# Enables SSH so your technician can help remotely.
# Download from: michaelgit.com/setup

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[ok]${NC} $1"; }
err()  { echo -e "${RED}[error]${NC} $1"; }
step() { echo -e "\n${GREEN}==>${NC} $1"; }

echo ""
echo -e "${CYAN}========================================"
echo "  MichaelGIT - Remote Setup"
echo "  michaelgit.com"
echo -e "========================================${NC}"
echo ""

# ── Check sudo ───────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo "This script needs administrator access."
    echo "You may be asked for your password."
    echo ""
    exec sudo bash "$0" "$@"
fi

# ── Enable SSH ───────────────────────────────────────────────────────
step "Setting up remote access"

if systemsetup -getremotelogin 2>/dev/null | grep -q "On"; then
    ok "Remote login already enabled"
else
    systemsetup -setremotelogin on
    ok "Remote login enabled"
fi

# ── Gather connection info ───────────────────────────────────────────
step "Your connection info"

LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "Could not detect")
HOSTNAME=$(hostname)
USERNAME=$(logname 2>/dev/null || echo "$SUDO_USER")
OS_VERSION="$(sw_vers -productName 2>/dev/null) $(sw_vers -productVersion 2>/dev/null)"

echo ""
echo -e "${YELLOW}========================================"
echo "  TELL YOUR TECHNICIAN:"
echo "========================================"
echo ""
echo "  IP Address:  $LAN_IP"
echo "  Username:    $USERNAME"
echo "  Computer:    $HOSTNAME"
echo "  OS:          $OS_VERSION"
echo ""
echo -e "========================================${NC}"
echo ""

ok "Remote access is ready!"
echo "Your technician can now connect to help you."
echo ""

# ── Self-destruct ────────────────────────────────────────────────────
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
rm -f "$SCRIPT_PATH" 2>/dev/null
echo "(This setup script has been cleaned up automatically.)"
echo ""
