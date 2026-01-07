#!/bin/bash
# ==============================================================================
# Flatpak Apps Setup (Multi-distro: Fedora, Ubuntu/Debian)
# ==============================================================================
set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

if ! check_internet; then
    echo "✅ Flatpak setup skipped (no internet)"
    exit 0
fi

# Skip on WSL (no GUI apps)
if is_wsl; then
    print_warning "Flatpak skipped on WSL (no GUI support)"
    exit 0
fi

echo "📱 Setting up Flatpak..."
print_success "Detected: $DISTRO"

# ==============================================================================
# Install Flatpak
# ==============================================================================
install_flatpak() {
    if command -v flatpak &>/dev/null; then
        print_success "Flatpak already installed"
        return 0
    fi
    
    echo "  Installing Flatpak..."
    case "$DISTRO" in
        fedora)
            sudo dnf install -y flatpak
            ;;
        ubuntu|debian)
            sudo apt update
            sudo apt install -y flatpak gnome-software-plugin-flatpak
            ;;
        arch)
            sudo pacman -S --noconfirm flatpak
            ;;
    esac
}

install_flatpak

# Add Flathub repository
if ! flatpak remote-list 2>/dev/null | grep -q flathub; then
    echo "  Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

# ==============================================================================
# Applications to install
# ==============================================================================
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
    
    # Media
    "com.mastermindzh.tidal-hifi"
    "com.spotify.Client"
    "org.videolan.VLC"
    
    # GNOME Extensions
    "org.gnome.Extensions"
    "com.mattjakeman.ExtensionManager"
    
    # Utilities
    "org.gnome.Calculator"
    "org.gnome.Evince"
    "org.gimp.GIMP"
    "com.github.tchx84.Flatseal"
)

echo "  Installing applications..."
for app in "${APPS[@]}"; do
    if ! flatpak list --user 2>/dev/null | grep -q "$app" && ! flatpak list 2>/dev/null | grep -q "$app"; then
        echo "    Installing $app..."
        flatpak install --user -y flathub "$app" 2>/dev/null || {
            print_warning "Failed to install $app"
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
flatpak list --app --columns=application 2>/dev/null | head -20
