#!/bin/bash
# ==============================================================================
# Base Packages Setup (Multi-distro: Fedora, Ubuntu/Debian, Arch)
# ==============================================================================
set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Check internet
if ! check_internet; then
    echo "✅ Base packages setup skipped (no internet)"
    exit 0
fi

echo "📦 Installing base packages..."
print_success "Detected: $DISTRO $(is_wsl && echo '(WSL)')"

# ==============================================================================
# Package Lists by Distro
# ==============================================================================

# Fedora packages
FEDORA_PACKAGES=(
    # Shell essentials
    "zsh" "git" "curl" "wget" "jq" "unzip" "util-linux-user"
    # Terminal (skip on WSL)
    # Modern CLI tools
    "bat" "lsd" "eza" "fd-find" "ripgrep" "zoxide" "fzf" "tealdeer"
    "btop" "direnv" "duf" "procs" "dust" "tokei" "hyperfine"
    # System info
    "fastfetch"
    # Development tools
    "make" "gcc" "gcc-c++" "openssl-devel" "readline-devel"
    "zlib-devel" "bzip2-devel" "libffi-devel" "sqlite-devel"
    # Ruby (for colorls)
    "ruby" "ruby-devel" "redhat-rpm-config"
    # System tools
    "htop" "tree" "xclip" "tmux" "screen"
)

# Ubuntu/Debian packages
UBUNTU_PACKAGES=(
    # Shell essentials
    "zsh" "git" "curl" "wget" "jq" "unzip" "passwd"
    # Modern CLI tools
    "bat" "lsd" "eza" "fd-find" "ripgrep" "zoxide" "fzf" "tldr"
    "btop" "direnv" "duf"
    # System info
    "fastfetch"
    # Development tools
    "make" "gcc" "g++" "libssl-dev" "libreadline-dev"
    "zlib1g-dev" "libbz2-dev" "libffi-dev" "libsqlite3-dev"
    # Ruby (for colorls)
    "ruby" "ruby-dev"
    # System tools
    "htop" "tree" "xclip" "tmux" "screen"
)

# Arch packages
ARCH_PACKAGES=(
    "zsh" "git" "curl" "wget" "jq" "unzip"
    "bat" "lsd" "eza" "fd" "ripgrep" "zoxide" "fzf" "tealdeer"
    "btop" "direnv" "duf" "procs" "dust" "tokei" "hyperfine"
    "fastfetch"
    "make" "gcc" "openssl" "readline" "zlib" "bzip2" "libffi" "sqlite"
    "ruby"
    "htop" "tree" "xclip" "tmux" "screen"
)

# ==============================================================================
# Install packages based on distro
# ==============================================================================
install_packages_for_distro() {
    case "$DISTRO" in
        fedora)
            # Add Kitty terminal (skip on WSL - no GUI)
            if ! is_wsl; then
                FEDORA_PACKAGES+=("kitty")
                # KeepassXC (skip on WSL)
                FEDORA_PACKAGES+=("keepassxc")
            fi
            
            echo "Installing ${#FEDORA_PACKAGES[@]} Fedora packages..."
            sudo dnf install -y --skip-unavailable "${FEDORA_PACKAGES[@]}" 2>/dev/null || {
                print_warning "Some packages failed. Installing individually..."
                for pkg in "${FEDORA_PACKAGES[@]}"; do
                    sudo dnf install -y --skip-unavailable "$pkg" 2>/dev/null || echo "  Skipped: $pkg"
                done
            }
            ;;
        ubuntu|debian)
            # Update package lists first
            sudo apt update 2>/dev/null
            
            # Some packages need universe/multiverse repo on Ubuntu
            if [[ "$DISTRO" == "ubuntu" ]]; then
                sudo add-apt-repository -y universe 2>/dev/null || true
                sudo add-apt-repository -y multiverse 2>/dev/null || true
            fi
            
            echo "Installing ${#UBUNTU_PACKAGES[@]} Ubuntu/Debian packages..."
            sudo apt install -y "${UBUNTU_PACKAGES[@]}" 2>/dev/null || {
                print_warning "Some packages failed. Installing individually..."
                for pkg in "${UBUNTU_PACKAGES[@]}"; do
                    sudo apt install -y "$pkg" 2>/dev/null || echo "  Skipped: $pkg"
                done
            }
            ;;
        arch)
            echo "Installing ${#ARCH_PACKAGES[@]} Arch packages..."
            sudo pacman -S --noconfirm --needed "${ARCH_PACKAGES[@]}" 2>/dev/null || {
                print_warning "Some packages failed. Installing individually..."
                for pkg in "${ARCH_PACKAGES[@]}"; do
                    sudo pacman -S --noconfirm --needed "$pkg" 2>/dev/null || echo "  Skipped: $pkg"
                done
            }
            ;;
        macos)
            echo "Installing packages via Homebrew..."
            brew install zsh git curl wget jq unzip bat lsd eza fd ripgrep zoxide fzf tealdeer \
                btop direnv duf procs dust tokei hyperfine fastfetch htop tree tmux 2>/dev/null || true
            ;;
        *)
            print_error "Unsupported distro: $DISTRO"
            exit 1
            ;;
    esac
}

install_packages_for_distro

# ==============================================================================
# Install colorls (Ruby gem - distro agnostic)
# ==============================================================================
echo "📦 Installing colorls..."
if ! command -v colorls &>/dev/null; then
    sudo gem update --system 2>/dev/null || true
    sudo gem install colorls 2>/dev/null || print_warning "colorls installation failed"
fi

# ==============================================================================
# Update tldr cache
# ==============================================================================
if command -v tldr &>/dev/null; then
    echo "📚 Updating tldr cache..."
    tldr --update 2>/dev/null || true
fi

echo "✅ Base packages installed"
