#!/bin/bash
# ==============================================================================
# Flatpak Apps Setup
# ==============================================================================
set -e

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
