#!/bin/bash
# ==============================================================================
# VPN Tools Setup (Multi-distro: Fedora, Ubuntu/Debian)
# Interactive version - asks before installing (default: no)
# ==============================================================================
set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

echo "🔐 VPN Tools Setup"
print_success "Detected: $DISTRO $(is_wsl && echo '(WSL)')"

if ! check_internet; then
    echo "✅ VPN tools setup skipped (no internet)"
    exit 0
fi

# Skip on WSL (VPN is typically handled by Windows)
if is_wsl; then
    print_warning "VPN tools skipped on WSL (use Windows VPN instead)"
    exit 0
fi

echo ""
echo "Select which VPN tools to install/manage:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# OpenVPN
# ==============================================================================
if check_and_ask "OpenVPN" "openvpn" "pkg_uninstall openvpn"; then
    echo "📦 Installing OpenVPN..."
    
    case "$DISTRO" in
        fedora)
            sudo dnf install -y openvpn NetworkManager-openvpn NetworkManager-openvpn-gnome 2>/dev/null && \
                print_success "OpenVPN installed" || print_warning "OpenVPN installation failed"
            ;;
        ubuntu|debian)
            sudo apt install -y openvpn network-manager-openvpn network-manager-openvpn-gnome 2>/dev/null && \
                print_success "OpenVPN installed" || print_warning "OpenVPN installation failed"
            ;;
        arch)
            sudo pacman -S --noconfirm openvpn networkmanager-openvpn 2>/dev/null && \
                print_success "OpenVPN installed" || print_warning "OpenVPN installation failed"
            ;;
        macos)
            brew install openvpn 2>/dev/null && \
                print_success "OpenVPN installed" || print_warning "OpenVPN installation failed"
            ;;
    esac
fi

# ==============================================================================
# WireGuard
# ==============================================================================
if check_and_ask "WireGuard" "wg" "pkg_uninstall wireguard-tools"; then
    echo "📦 Installing WireGuard..."
    
    case "$DISTRO" in
        fedora)
            sudo dnf install -y wireguard-tools 2>/dev/null && \
                print_success "WireGuard installed" || print_warning "WireGuard installation failed"
            ;;
        ubuntu|debian)
            sudo apt install -y wireguard-tools 2>/dev/null && \
                print_success "WireGuard installed" || print_warning "WireGuard installation failed"
            ;;
        arch)
            sudo pacman -S --noconfirm wireguard-tools 2>/dev/null && \
                print_success "WireGuard installed" || print_warning "WireGuard installation failed"
            ;;
        macos)
            brew install wireguard-tools 2>/dev/null && \
                print_success "WireGuard installed" || print_warning "WireGuard installation failed"
            ;;
    esac
    
    # Create WireGuard config directory
    if [[ ! -d /etc/wireguard ]]; then
        sudo mkdir -p /etc/wireguard
        sudo chmod 700 /etc/wireguard
    fi
fi

# Restart NetworkManager if any VPN tool was installed
if command -v systemctl &>/dev/null; then
    sudo systemctl restart NetworkManager 2>/dev/null || true
fi

echo ""
echo "✅ VPN tools setup complete"
echo ""
echo "📋 Usage:"
echo "  • OpenVPN: Import .ovpn file via Settings → Network → VPN"
echo "  • WireGuard: nmcli connection import type wireguard file /path/to/config.conf"
echo "  • Or use: 'nmtui' for a text-based interface"
