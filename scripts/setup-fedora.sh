#!/bin/bash
# ==============================================================================
# Fedora Base Packages Setup
# ==============================================================================
set -e

echo "📦 Installing Fedora base packages..."

# Essential packages
PACKAGES=(
    # Shell essentials
    "zsh"
    "git"
    "curl"
    "wget"
    "jq"
    "unzip"
    "util-linux-user"
    
    # Modern CLI tools
    "bat"           # Better cat
    "lsd"           # Better ls
    "fd-find"       # Better find
    "ripgrep"       # Better grep
    "zoxide"        # Smart cd
    "fzf"           # Fuzzy finder
    "tealdeer"      # Fast tldr
    "btop"          # Better top
    "direnv"        # Per-directory env
    
    # Development tools
    "make"
    "gcc"
    "gcc-c++"
    "openssl-devel"
    "readline-devel"
    "zlib-devel"
    "bzip2-devel"
    "libffi-devel"
    "sqlite-devel"
    
    # Ruby (for colorls)
    "ruby"
    "ruby-devel"
    "redhat-rpm-config"
    
    # System tools
    "testdisk"
    "htop"
    "neofetch"
    "tree"
    "xclip"
)

# Install packages
echo "Installing ${#PACKAGES[@]} packages..."
sudo dnf install -y "${PACKAGES[@]}" || {
    echo "⚠️ Some packages failed to install. Trying individually..."
    for pkg in "${PACKAGES[@]}"; do
        sudo dnf install -y "$pkg" 2>/dev/null || echo "  Skipped: $pkg"
    done
}

# Update gem and install colorls
echo "📦 Installing colorls..."
if ! command -v colorls &>/dev/null; then
    sudo gem update --system 2>/dev/null || true
    sudo gem install colorls 2>/dev/null || echo "⚠️ colorls installation failed"
fi

# Update tldr cache
if command -v tldr &>/dev/null; then
    echo "📚 Updating tldr cache..."
    tldr --update 2>/dev/null || true
fi

echo "✅ Fedora base packages installed"
