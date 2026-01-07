#!/bin/bash
# ==============================================================================
# Fedora Base Packages Setup
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
    echo "  ⚠️  This script requires internet to download packages."
    return 1
}

if ! check_internet; then
    echo "✅ Fedora base packages setup skipped (no internet)"
    exit 0
fi

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
    
    # Terminal emulator
    "kitty"
    
    # Modern CLI tools
    "bat"           # Better cat
    "lsd"           # Better ls
    "eza"           # Modern ls (alternative)
    "fd-find"       # Better find
    "ripgrep"       # Better grep
    "zoxide"        # Smart cd
    "fzf"           # Fuzzy finder
    "tealdeer"      # Fast tldr
    "btop"          # Better top
    "direnv"        # Per-directory env
    "duf"           # Disk usage viewer
    "procs"         # Modern ps
    "dust"          # Disk usage analyzer
    "tokei"         # Code statistics
    "hyperfine"     # Benchmarking tool
    
    # System info (fastfetch replaces deprecated neofetch)
    "fastfetch"
    
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
    "tree"
    "xclip"
    "tmux"
    "screen"
    
    # Security
    "keepassxc"
)

# Install packages with --skip-unavailable flag
echo "Installing ${#PACKAGES[@]} packages..."
sudo dnf install -y --skip-unavailable "${PACKAGES[@]}" 2>/dev/null || {
    echo "⚠️ Some packages failed to install. Trying individually..."
    for pkg in "${PACKAGES[@]}"; do
        sudo dnf install -y --skip-unavailable "$pkg" 2>/dev/null || echo "  Skipped: $pkg"
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
