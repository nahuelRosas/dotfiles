#!/bin/bash
# ==============================================================================
# VPN Tools Setup (Multi-distro: Fedora, Ubuntu/Debian)
# ==============================================================================
set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

if ! check_internet; then
    echo "✅ VPN tools setup skipped (no internet)"
    exit 0
fi

# Skip on WSL (VPN is typically handled by Windows)
if is_wsl; then
    print_warning "VPN tools skipped on WSL (use Windows VPN instead)"
    exit 0
fi

echo "🔐 Setting up VPN tools..."
print_success "Detected: $DISTRO"

# ==============================================================================
# Install VPN packages by distro
# ==============================================================================
case "$DISTRO" in
    fedora)
        VPN_PACKAGES=(
            "openvpn"
            "NetworkManager-openvpn"
            "NetworkManager-openvpn-gnome"
            "wireguard-tools"
            "NetworkManager-tui"
        )
        sudo dnf install -y --skip-unavailable "${VPN_PACKAGES[@]}" 2>/dev/null || {
            print_warning "Some packages failed. Installing individually..."
            for pkg in "${VPN_PACKAGES[@]}"; do
                sudo dnf install -y "$pkg" 2>/dev/null || echo "  Skipped: $pkg"
            done
        }
        ;;
    ubuntu|debian)
        VPN_PACKAGES=(
            "openvpn"
            "network-manager-openvpn"
            "network-manager-openvpn-gnome"
            "wireguard-tools"
            "network-manager"
        )
        sudo apt update
        sudo apt install -y "${VPN_PACKAGES[@]}" 2>/dev/null || {
            print_warning "Some packages failed. Installing individually..."
            for pkg in "${VPN_PACKAGES[@]}"; do
                sudo apt install -y "$pkg" 2>/dev/null || echo "  Skipped: $pkg"
            done
        }
        ;;
    arch)
        sudo pacman -S --noconfirm openvpn networkmanager-openvpn wireguard-tools 2>/dev/null || true
        ;;
    macos)
        brew install openvpn wireguard-tools 2>/dev/null || true
        ;;
esac

# Restart NetworkManager to pick up new plugins
if command -v systemctl &>/dev/null; then
    echo "  Restarting NetworkManager..."
    sudo systemctl restart NetworkManager 2>/dev/null || true
fi

# Create WireGuard config directory
if [[ ! -d /etc/wireguard ]]; then
    sudo mkdir -p /etc/wireguard
    sudo chmod 700 /etc/wireguard
fi

# Verify installation
echo ""
echo "✅ VPN tools installed:"

if command -v openvpn &>/dev/null; then
    echo "  • OpenVPN: $(openvpn --version 2>/dev/null | head -1 | awk '{print $2}')"
fi

if command -v wg &>/dev/null; then
    echo "  • WireGuard: $(wg --version 2>/dev/null | awk '{print $2}')"
fi

echo ""
echo "📋 Usage:"
echo "  • OpenVPN: Import .ovpn file via Settings → Network → VPN"
echo "  • WireGuard: nmcli connection import type wireguard file /path/to/config.conf"
echo "  • Or use: 'nmtui' for a text-based interface"
