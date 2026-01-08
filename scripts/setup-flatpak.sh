#!/bin/bash
# ==============================================================================
# Flatpak Apps Setup (Multi-distro: Fedora, Ubuntu/Debian)
# Interactive version - asks before installing (default: no)
# ==============================================================================
set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

echo "📱 Flatpak Apps Setup"
print_success "Detected: $DISTRO $(is_wsl && echo '(WSL)')"

if ! check_internet; then
    echo "✅ Flatpak setup skipped (no internet)"
    exit 0
fi

# Skip on WSL (no GUI apps)
if is_wsl; then
    print_warning "Flatpak skipped on WSL (no GUI support)"
    exit 0
fi

# ==============================================================================
# Install Flatpak itself
# ==============================================================================
if ! command -v flatpak &>/dev/null; then
    if ask_yes_no "Flatpak not installed. Install Flatpak?" "n"; then
        echo "📦 Installing Flatpak..."
        case "$DISTRO" in
            fedora)
                sudo dnf install -y flatpak && print_success "Flatpak installed"
                ;;
            ubuntu|debian)
                sudo apt update
                sudo apt install -y flatpak gnome-software-plugin-flatpak && print_success "Flatpak installed"
                ;;
            arch)
                sudo pacman -S --noconfirm flatpak && print_success "Flatpak installed"
                ;;
        esac
        
        # Add Flathub
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null
    else
        echo "✅ Skipping Flatpak setup"
        exit 0
    fi
fi

echo ""
echo "Select which Flatpak apps to install:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# Applications - categorized
# ==============================================================================

# Helper to check and install flatpak app
check_flatpak_app() {
    local name="$1"
    local app_id="$2"
    
    if flatpak list 2>/dev/null | grep -q "$app_id"; then
        echo "  ✅ $name already installed"
        if ask_yes_no "     Remove $name?" "n"; then
            echo "  🗑️  Removing $name..."
            flatpak uninstall -y "$app_id" 2>/dev/null && print_success "$name removed" || print_warning "Failed to remove $name"
        fi
        return 1
    fi
    
    if ask_yes_no "Install $name?" "n"; then
        return 0
    fi
    return 1
}

echo "── Development ──"
check_flatpak_app "Android Studio" "com.google.AndroidStudio" && \
    flatpak install --user -y flathub com.google.AndroidStudio 2>/dev/null

check_flatpak_app "Postman" "com.getpostman.Postman" && \
    flatpak install --user -y flathub com.getpostman.Postman 2>/dev/null

echo ""
echo "── Communication ──"
check_flatpak_app "Slack" "com.slack.Slack" && \
    flatpak install --user -y flathub com.slack.Slack 2>/dev/null

check_flatpak_app "Zoom" "us.zoom.Zoom" && \
    flatpak install --user -y flathub us.zoom.Zoom 2>/dev/null

echo ""
echo "── Productivity ──"
check_flatpak_app "WPS Office" "com.wps.Office" && \
    flatpak install --user -y flathub com.wps.Office 2>/dev/null

check_flatpak_app "Obsidian" "md.obsidian.Obsidian" && \
    flatpak install --user -y flathub md.obsidian.Obsidian 2>/dev/null

echo ""
echo "── Media ──"
check_flatpak_app "Spotify" "com.spotify.Client" && \
    flatpak install --user -y flathub com.spotify.Client 2>/dev/null

check_flatpak_app "Tidal" "com.mastermindzh.tidal-hifi" && \
    flatpak install --user -y flathub com.mastermindzh.tidal-hifi 2>/dev/null

check_flatpak_app "VLC" "org.videolan.VLC" && \
    flatpak install --user -y flathub org.videolan.VLC 2>/dev/null

echo ""
echo "── Utilities ──"
check_flatpak_app "GNOME Extensions Manager" "com.mattjakeman.ExtensionManager" && \
    flatpak install --user -y flathub com.mattjakeman.ExtensionManager 2>/dev/null

check_flatpak_app "Flatseal (Permissions Manager)" "com.github.tchx84.Flatseal" && \
    flatpak install --user -y flathub com.github.tchx84.Flatseal 2>/dev/null

check_flatpak_app "GIMP" "org.gimp.GIMP" && \
    flatpak install --user -y flathub org.gimp.GIMP 2>/dev/null

echo ""
echo "✅ Flatpak setup complete"
