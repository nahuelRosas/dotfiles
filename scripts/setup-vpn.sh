#!/bin/bash
# ==============================================================================
# VPN Tools Setup for Fedora
# ==============================================================================
set -e

echo "🔐 Setting up VPN tools..."

# Packages to install
VPN_PACKAGES=(
    # OpenVPN
    "openvpn"
    "NetworkManager-openvpn"
    "NetworkManager-openvpn-gnome"
    
    # WireGuard
    "wireguard-tools"
    
    # NetworkManager integration
    "NetworkManager-tui"
)

# Install packages
echo "  Installing VPN packages..."
sudo dnf install -y --skip-unavailable "${VPN_PACKAGES[@]}" 2>/dev/null || {
    echo "  ⚠️ Some packages failed. Installing individually..."
    for pkg in "${VPN_PACKAGES[@]}"; do
        sudo dnf install -y "$pkg" 2>/dev/null || echo "  Skipped: $pkg"
    done
}

# Enable and restart NetworkManager to pick up new plugins
echo "  Restarting NetworkManager..."
sudo systemctl restart NetworkManager 2>/dev/null || true

# Create WireGuard config directory if it doesn't exist
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
echo "  • WireGuard: Import config via 'nmcli connection import type wireguard file /path/to/config.conf'"
echo "  • Or use: 'nmtui' for a text-based interface"
