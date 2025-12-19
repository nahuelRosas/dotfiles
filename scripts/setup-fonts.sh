#!/bin/bash
# ==============================================================================
# Nerd Fonts Setup
# ==============================================================================
set -e

echo "🔤 Installing Nerd Fonts..."

# Font to install
FONT_NAME="FiraCode"
FONT_DIR="/usr/local/share/fonts"

# Get latest version
echo "  Checking latest version..."
LATEST_VERSION=$(curl -s "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" | jq -r '.tag_name')

if [[ -z "$LATEST_VERSION" ]] || [[ "$LATEST_VERSION" == "null" ]]; then
    echo "⚠️ Could not fetch latest version. Using v3.1.1"
    LATEST_VERSION="v3.1.1"
fi

FONT_VERSION_DIR="$FONT_DIR/${FONT_NAME}-${LATEST_VERSION}"

# Check if already installed
if [[ -d "$FONT_VERSION_DIR" ]]; then
    echo "  $FONT_NAME Nerd Font $LATEST_VERSION already installed"
    exit 0
fi

# Download URL
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${LATEST_VERSION}/${FONT_NAME}.zip"

# Temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "  Downloading $FONT_NAME Nerd Font $LATEST_VERSION..."
curl -L -o "${FONT_NAME}.zip" "$DOWNLOAD_URL" 2>/dev/null

if ! file "${FONT_NAME}.zip" | grep -q "Zip archive"; then
    echo "⚠️ Download failed"
    cd -
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "  Extracting..."
unzip -o "${FONT_NAME}.zip" -d "$TEMP_DIR" >/dev/null 2>&1

# Remove old versions
echo "  Removing old versions..."
sudo find "$FONT_DIR" -type d -name "${FONT_NAME}-*" -exec rm -rf {} + 2>/dev/null || true

# Install new version
echo "  Installing to $FONT_VERSION_DIR..."
sudo mkdir -p "$FONT_VERSION_DIR"
sudo mv "$TEMP_DIR"/*.ttf "$FONT_VERSION_DIR/" 2>/dev/null || \
sudo mv "$TEMP_DIR"/*.otf "$FONT_VERSION_DIR/" 2>/dev/null || true

# Update font cache
echo "  Updating font cache..."
sudo fc-cache -fv >/dev/null 2>&1

# Cleanup
cd -
rm -rf "$TEMP_DIR"

# Verify installation
if fc-list | grep -i "firacode.*nerd" >/dev/null; then
    echo "✅ $FONT_NAME Nerd Font $LATEST_VERSION installed successfully"
else
    echo "⚠️ Font installed but not detected. Try restarting your terminal."
fi

# Additional fonts (optional)
install_additional_font() {
    local font_name="$1"
    local font_version_dir="$FONT_DIR/${font_name}-${LATEST_VERSION}"
    
    if [[ -d "$font_version_dir" ]]; then
        return
    fi
    
    echo "  Installing $font_name Nerd Font..."
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${LATEST_VERSION}/${font_name}.zip"
    local temp_dir=$(mktemp -d)
    
    curl -sL -o "$temp_dir/${font_name}.zip" "$download_url"
    
    if file "$temp_dir/${font_name}.zip" | grep -q "Zip archive"; then
        unzip -o "$temp_dir/${font_name}.zip" -d "$temp_dir" >/dev/null 2>&1
        sudo mkdir -p "$font_version_dir"
        sudo mv "$temp_dir"/*.ttf "$font_version_dir/" 2>/dev/null || true
        sudo mv "$temp_dir"/*.otf "$font_version_dir/" 2>/dev/null || true
    fi
    
    rm -rf "$temp_dir"
}

# Uncomment to install additional fonts
# install_additional_font "JetBrainsMono"
# install_additional_font "Hack"
# install_additional_font "CascadiaCode"

# Final font cache update
sudo fc-cache -fv >/dev/null 2>&1

echo "✅ Fonts installation complete"
