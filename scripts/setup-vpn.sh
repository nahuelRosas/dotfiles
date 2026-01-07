#!/bin/bash
# ==============================================================================
# VPN Tools Setup for Fedora
# ==============================================================================
set -e

check_internet() {
    # Method 1: HTTP check (works through proxies and when ICMP is blocked)
    if curl -fsSL --connect-timeout 5 --max-time 10 https://www.google.com -o /dev/null 2>/dev/null; then
        return 0
    fi
    
    # Method 2: DNS resolution check
    if host google.com &>/dev/null 2>&1 || nslookup google.com &>/dev/null 2>&1; then
        # DNS works, try a different HTTP endpoint
        if curl -fsSL --connect-timeout 5 --max-time 10 https://cloudflare.com -o /dev/null 2>/dev/null; then
            return 0
        fi
    fi
    
    # Method 3: ICMP ping (fallback)
    if ping -c 1 -W 3 8.8.8.8 &>/dev/null || ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
        return 0
    fi
    
    echo "  ⚠️  No internet connection detected."
    echo "  ⚠️  This script requires internet to download VPN tools."
    return 1
}

if ! check_internet; then
    echo "✅ VPN tools setup skipped (no internet)"
    exit 0
fi

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
