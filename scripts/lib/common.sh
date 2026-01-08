#!/bin/bash
# ==============================================================================
# Common Library - Shared functions for all setup scripts
# Source this from setup scripts: source "$(dirname "$0")/lib/common.sh"
# ==============================================================================

# Prevent multiple sourcing
[[ -n "$_COMMON_LIB_LOADED" ]] && return 0
_COMMON_LIB_LOADED=1

# ==============================================================================
# Colors
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ==============================================================================
# Helper Functions
# ==============================================================================
print_step() { echo -e "${BLUE}▶${NC} $1"; }
print_success() { echo -e "${GREEN}✔${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✖${NC} $1"; }

# ==============================================================================
# Environment Detection
# ==============================================================================
DISTRO=""
PKG_MANAGER=""
PKG_INSTALL=""
PKG_UPDATE=""
IS_WSL=false

detect_distro() {
    # Already detected
    [[ -n "$DISTRO" ]] && return 0
    
    # Detect WSL
    if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
        IS_WSL=true
    fi
    
    if [[ -f /etc/fedora-release ]]; then
        DISTRO="fedora"
        PKG_MANAGER="dnf"
        PKG_INSTALL="sudo dnf install -y --skip-unavailable"
        PKG_UPDATE="sudo dnf upgrade -y"
    elif [[ -f /etc/debian_version ]]; then
        if grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
            DISTRO="ubuntu"
        else
            DISTRO="debian"
        fi
        PKG_MANAGER="apt"
        PKG_INSTALL="sudo apt install -y"
        PKG_UPDATE="sudo apt update && sudo apt upgrade -y"
    elif [[ -f /etc/arch-release ]]; then
        DISTRO="arch"
        PKG_MANAGER="pacman"
        PKG_INSTALL="sudo pacman -S --noconfirm"
        PKG_UPDATE="sudo pacman -Syu --noconfirm"
    elif [[ "$(uname)" == "Darwin" ]]; then
        DISTRO="macos"
        PKG_MANAGER="brew"
        PKG_INSTALL="brew install"
        PKG_UPDATE="brew update && brew upgrade"
    else
        print_error "Unsupported OS"
        return 1
    fi
    
    export DISTRO PKG_MANAGER PKG_INSTALL PKG_UPDATE IS_WSL
}

is_wsl() {
    detect_distro
    [[ "$IS_WSL" == true ]]
}

is_fedora() { detect_distro && [[ "$DISTRO" == "fedora" ]]; }
is_ubuntu() { detect_distro && [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; }
is_arch() { detect_distro && [[ "$DISTRO" == "arch" ]]; }
is_macos() { detect_distro && [[ "$DISTRO" == "macos" ]]; }

# ==============================================================================
# NVM/Node.js Loading (for scripts that need npm)
# ==============================================================================
_NVM_LOADED=false

load_nvm() {
    [[ "$_NVM_LOADED" == true ]] && return 0
    
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        source "$NVM_DIR/nvm.sh"
        _NVM_LOADED=true
        return 0
    fi
    return 1
}

# Ensure npm is available (loads NVM if needed)
ensure_npm() {
    load_nvm
    command -v npm &>/dev/null
}

# Run npm command with NVM loaded
run_npm() {
    ensure_npm || { print_warning "npm not available"; return 1; }
    npm "$@"
}

# ==============================================================================
# Interactive Prompts
# ==============================================================================

# Simple yes/no prompt (default: no)
ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    
    local hint
    if [[ "$default" == "y" ]]; then
        hint="[Y/n]"
    else
        hint="[y/N]"
    fi
    
    read -p "$prompt $hint: " response
    response=${response:-$default}
    
    [[ "$response" =~ ^[Yy] ]]
}

# Check if tool is installed and ask what to do
# Returns: 0 = install, 1 = skip, 2 = uninstall requested
# Usage: check_and_ask "Tool Name" "command_name" "uninstall_command (optional)"
check_and_ask() {
    local name="$1"
    local cmd="$2"
    local uninstall_cmd="${3:-}"
    
    if command -v "$cmd" &>/dev/null; then
        # Already installed
        if [[ "${FORCE_REINSTALL:-false}" == "true" ]]; then
            return 0  # Reinstall
        fi
        
        echo "  ✅ $name already installed"
        
        if [[ -n "$uninstall_cmd" ]]; then
            if ask_yes_no "     Remove $name?" "n"; then
                echo "  🗑️  Removing $name..."
                eval "$uninstall_cmd" 2>/dev/null && print_success "$name removed" || print_warning "Failed to remove $name"
            fi
        fi
        
        return 1  # Skip installation
    fi
    
    # Not installed - ask if user wants to install
    if ask_yes_no "Install $name?" "n"; then
        return 0  # Install
    fi
    
    return 1  # Skip
}

# Uninstall a system package
pkg_uninstall() {
    local pkg="$1"
    
    case "$PKG_MANAGER" in
        dnf) sudo dnf remove -y "$pkg" 2>/dev/null ;;
        apt) sudo apt remove -y "$pkg" 2>/dev/null ;;
        pacman) sudo pacman -R --noconfirm "$pkg" 2>/dev/null ;;
        brew) brew uninstall "$pkg" 2>/dev/null ;;
    esac
}

# Uninstall npm global package
npm_uninstall() {
    ensure_npm && run_npm uninstall -g "$1" 2>/dev/null
}

# ==============================================================================
# Package Installation
# ==============================================================================
pkg_install() {
    detect_distro
    $PKG_INSTALL "$@" 2>/dev/null
}

pkg_update() {
    detect_distro
    eval "$PKG_UPDATE" 2>/dev/null
}

# Check if package is installed
pkg_installed() {
    local pkg="$1"
    case "$PKG_MANAGER" in
        dnf) rpm -q "$pkg" &>/dev/null ;;
        apt) dpkg -l "$pkg" 2>/dev/null | grep -q "^ii" ;;
        pacman) pacman -Qi "$pkg" &>/dev/null ;;
        brew) brew list "$pkg" &>/dev/null ;;
    esac
}

# ==============================================================================
# Package Name Mapping (Fedora → Ubuntu equivalents)
# ==============================================================================
declare -A PKG_MAP_UBUNTU=(
    # Base packages
    ["util-linux-user"]="passwd"
    ["fd-find"]="fd-find"
    ["tealdeer"]="tldr"
    ["lsd"]="lsd"
    ["btop"]="btop"
    ["duf"]="duf"
    ["procs"]="procps"
    ["dust"]="du-dust"
    ["tokei"]="tokei"
    ["hyperfine"]="hyperfine"
    ["fastfetch"]="fastfetch"
    ["bat"]="bat"
    ["eza"]="eza"
    ["ripgrep"]="ripgrep"
    ["zoxide"]="zoxide"
    ["fzf"]="fzf"
    ["direnv"]="direnv"
    
    # Development
    ["gcc-c++"]="g++"
    ["openssl-devel"]="libssl-dev"
    ["readline-devel"]="libreadline-dev"
    ["zlib-devel"]="zlib1g-dev"
    ["bzip2-devel"]="libbz2-dev"
    ["libffi-devel"]="libffi-dev"
    ["sqlite-devel"]="libsqlite3-dev"
    ["ruby-devel"]="ruby-dev"
    ["redhat-rpm-config"]=""
    
    # Docker
    ["docker-ce"]="docker-ce"
    ["docker-ce-cli"]="docker-ce-cli"
    ["containerd.io"]="containerd.io"
    ["docker-buildx-plugin"]="docker-buildx-plugin"
    ["docker-compose-plugin"]="docker-compose-plugin"
    
    # VPN
    ["NetworkManager-openvpn"]="network-manager-openvpn"
    ["NetworkManager-openvpn-gnome"]="network-manager-openvpn-gnome"
    ["wireguard-tools"]="wireguard-tools"
    ["NetworkManager-tui"]="network-manager"
    
    # Flutter dependencies
    ["clang"]="clang"
    ["cmake"]="cmake"
    ["ninja-build"]="ninja-build"
    ["gtk3-devel"]="libgtk-3-dev"
    ["libblkid-devel"]="libblkid-dev"
    ["lzma-sdk-devel"]="liblzma-dev"
    ["mesa-libGLU-devel"]="libglu1-mesa-dev"
    ["libstdc++-static"]=""
    
    # Java
    ["java-17-openjdk"]="openjdk-17-jdk"
    ["java-17-openjdk-devel"]=""
)

# Get the package name for current distro
get_pkg_name() {
    local fedora_name="$1"
    
    if is_fedora; then
        echo "$fedora_name"
    elif is_ubuntu; then
        local ubuntu_name="${PKG_MAP_UBUNTU[$fedora_name]:-$fedora_name}"
        # Skip empty mappings (package doesn't exist on Ubuntu)
        [[ -z "$ubuntu_name" ]] && return 1
        echo "$ubuntu_name"
    else
        echo "$fedora_name"
    fi
}

# Install packages with automatic name translation
install_packages() {
    detect_distro
    local packages=()
    
    for pkg in "$@"; do
        local translated
        if translated=$(get_pkg_name "$pkg"); then
            packages+=("$translated")
        fi
    done
    
    [[ ${#packages[@]} -eq 0 ]] && return 0
    pkg_install "${packages[@]}"
}

# ==============================================================================
# Network Check (with retry)
# ==============================================================================
check_internet() {
    local max_retries=3
    local retry_delay=2
    
    for ((attempt=1; attempt<=max_retries; attempt++)); do
        if curl -fsSL --connect-timeout 5 --max-time 10 https://www.google.com -o /dev/null 2>/dev/null; then
            return 0
        fi
        if host google.com &>/dev/null 2>&1 || nslookup google.com &>/dev/null 2>&1; then
            if curl -fsSL --connect-timeout 5 --max-time 10 https://cloudflare.com -o /dev/null 2>/dev/null; then
                return 0
            fi
        fi
        if ping -c 1 -W 3 8.8.8.8 &>/dev/null || ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
            return 0
        fi
        [[ $attempt -lt $max_retries ]] && sleep $retry_delay
    done
    
    print_error "No internet connection detected"
    return 1
}

# ==============================================================================
# Initialize on source
# ==============================================================================
detect_distro
