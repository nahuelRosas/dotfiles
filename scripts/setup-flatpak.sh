#!/bin/bash
# ==============================================================================
# Flatpak Apps Setup
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
    echo "  ⚠️  This script requires internet to download Flatpak applications."
    return 1
}

if ! check_internet; then
    echo "✅ Flatpak setup skipped (no internet)"
    exit 0
fi

echo "📱 Setting up Flatpak..."

# Install Flatpak if not present
if ! command -v flatpak &>/dev/null; then
    echo "  Installing Flatpak..."
    sudo dnf install -y flatpak
fi

# Add Flathub repository
if ! flatpak remote-list | grep -q flathub; then
    echo "  Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

# Applications to install
APPS=(
    # Development
    "com.google.AndroidStudio"
    "com.getpostman.Postman"
    
    # Communication
    "com.slack.Slack"
    "us.zoom.Zoom"
    
    # Productivity
    "com.wps.Office"
    "md.obsidian.Obsidian"
    # "org.keepassxc.KeePassXC"  # Install via DNF instead: sudo dnf install keepassxc
    
    # Media
    "com.mastermindzh.tidal-hifi"
    "com.spotify.Client"
    "org.videolan.VLC"
    
    # GNOME Extensions
    "org.gnome.Extensions"
    "com.mattjakeman.ExtensionManager"
    
    # Utilities
    "org.gnome.Calculator"
    "org.gnome.Evince"  # PDF viewer
    "org.gimp.GIMP"
    "com.github.tchx84.Flatseal"  # Flatpak permissions manager
)

echo "  Installing applications..."
for app in "${APPS[@]}"; do
    # Check if installed
    if ! flatpak list --user | grep -q "$app" && ! flatpak list | grep -q "$app"; then
        echo "    Installing $app..."
        flatpak install --user -y flathub "$app" 2>/dev/null || {
            echo "    ⚠️ Failed to install $app"
        }
    else
        echo "    $app already installed"
    fi
done

# Update all Flatpak apps
echo "  Updating Flatpak applications..."
flatpak update -y 2>/dev/null || true

# Update appstream data
echo "  Updating appstream data..."
flatpak update --appstream 2>/dev/null || true

echo "✅ Flatpak setup complete"

# List installed apps
echo ""
echo "📋 Installed Flatpak applications:"
flatpak list --app --columns=application | head -20
