#!/bin/bash
# ==============================================================================
# Development Tools Setup (Multi-distro: Fedora, Ubuntu/Debian, Arch)
# ==============================================================================

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

if ! check_internet; then
    echo "✅ Development tools setup skipped (no internet)"
    exit 0
fi

echo "🔧 Installing development tools..."
print_success "Detected: $DISTRO $(is_wsl && echo '(WSL)')"

# ==============================================================================
# LAZYGIT (Binary install - works on all distros)
# ==============================================================================
echo "📦 Setting up Lazygit..."
setup_lazygit() {
    if [[ "${FORCE_REINSTALL:-false}" != "true" ]] && command -v lazygit &>/dev/null; then
        echo "  Lazygit already installed: $(lazygit --version 2>/dev/null | head -1)"
        return 0
    fi
    
    local version
    version=$(curl -s --connect-timeout 10 "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" 2>/dev/null | jq -r '.tag_name' 2>/dev/null | sed 's/^v//')
    
    if [[ -z "$version" || "$version" == "null" ]]; then
        print_warning "Could not fetch Lazygit version"
        return 1
    fi
    
    echo "  Downloading Lazygit v$version..."
    local download_url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_x86_64.tar.gz"
    local temp_dir="/tmp/lazygit-$$"
    
    mkdir -p "$temp_dir"
    if curl -fsSL --connect-timeout 10 "$download_url" 2>/dev/null | tar xz -C "$temp_dir" 2>/dev/null; then
        sudo mv "$temp_dir/lazygit" /usr/local/bin/
        sudo chmod +x /usr/local/bin/lazygit
        print_success "Lazygit v$version installed"
    else
        print_warning "Lazygit download failed"
    fi
    rm -rf "$temp_dir"
}
setup_lazygit || true

# ==============================================================================
# VSCODE
# ==============================================================================
echo "📦 Setting up VSCode..."
setup_vscode() {
    # Skip on WSL (use Windows VSCode with WSL extension)
    if is_wsl; then
        print_warning "VSCode skipped on WSL (use Windows VSCode with Remote-WSL extension)"
        return 0
    fi
    
    if [[ "${FORCE_REINSTALL:-false}" != "true" ]] && command -v code &>/dev/null; then
        echo "  VSCode already installed"
        return 0
    fi
    
    case "$DISTRO" in
        fedora)
            local vscode_rpm="/tmp/vscode.rpm"
            echo "  Downloading VSCode..."
            if curl -L --connect-timeout 10 -o "$vscode_rpm" "https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64" 2>/dev/null; then
                sudo dnf install -y "$vscode_rpm" 2>/dev/null || print_warning "VSCode installation failed"
            fi
            rm -f "$vscode_rpm"
            ;;
        ubuntu|debian)
            # Add Microsoft repo
            if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
                curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg 2>/dev/null || true
                echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
                sudo apt update
            fi
            sudo apt install -y code 2>/dev/null || print_warning "VSCode installation failed"
            ;;
        arch)
            # VSCode is in AUR, suggest using yay
            print_warning "VSCode: Install via AUR (yay -S visual-studio-code-bin)"
            ;;
    esac
}
setup_vscode || true

# ==============================================================================
# BRAVE BROWSER
# ==============================================================================
echo "📦 Setting up Brave Browser..."
setup_brave() {
    # Skip on WSL
    if is_wsl; then
        print_warning "Brave skipped on WSL (use Windows browser)"
        return 0
    fi
    
    if [[ "${FORCE_REINSTALL:-false}" != "true" ]] && command -v brave-browser &>/dev/null; then
        echo "  Brave already installed"
        return 0
    fi
    
    case "$DISTRO" in
        fedora)
            if [ ! -f /etc/yum.repos.d/brave-browser.repo ]; then
                sudo curl -fsSL https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo -o /etc/yum.repos.d/brave-browser.repo 2>/dev/null || true
                sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc 2>/dev/null || true
            fi
            sudo dnf install -y brave-browser 2>/dev/null || print_warning "Brave installation failed"
            ;;
        ubuntu|debian)
            if [ ! -f /etc/apt/sources.list.d/brave-browser.list ]; then
                sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg 2>/dev/null || true
                echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser.list > /dev/null
                sudo apt update
            fi
            sudo apt install -y brave-browser 2>/dev/null || print_warning "Brave installation failed"
            ;;
        arch)
            print_warning "Brave: Install via AUR (yay -S brave-bin)"
            ;;
    esac
}
setup_brave || true

# ==============================================================================
# GITHUB CLI
# ==============================================================================
echo "📦 Setting up GitHub CLI..."
setup_github_cli() {
    if [[ "${FORCE_REINSTALL:-false}" != "true" ]] && command -v gh &>/dev/null; then
        echo "  GitHub CLI already installed"
        return 0
    fi
    
    case "$DISTRO" in
        fedora)
            sudo dnf install -y --skip-unavailable gh 2>/dev/null || print_warning "gh installation failed"
            ;;
        ubuntu|debian)
            # Add GitHub CLI repo
            if [ ! -f /etc/apt/sources.list.d/github-cli.list ]; then
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null || true
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                sudo apt update
            fi
            sudo apt install -y gh 2>/dev/null || print_warning "gh installation failed"
            ;;
        arch)
            sudo pacman -S --noconfirm github-cli 2>/dev/null || true
            ;;
    esac
}
setup_github_cli || true

# ==============================================================================
# ADDITIONAL TOOLS
# ==============================================================================
echo "📦 Installing additional tools..."

case "$DISTRO" in
    fedora)
        TOOLS=("neovim" "tmux" "shellcheck")
        for tool in "${TOOLS[@]}"; do
            if [[ "${FORCE_REINSTALL:-false}" == "true" ]] || ! rpm -q "$tool" &>/dev/null; then
                sudo dnf install -y --skip-unavailable "$tool" 2>/dev/null || echo "  Skipped: $tool"
            fi
        done
        ;;
    ubuntu|debian)
        TOOLS=("neovim" "tmux" "shellcheck")
        sudo apt install -y "${TOOLS[@]}" 2>/dev/null || {
            for tool in "${TOOLS[@]}"; do
                sudo apt install -y "$tool" 2>/dev/null || echo "  Skipped: $tool"
            done
        }
        ;;
    arch)
        sudo pacman -S --noconfirm neovim tmux shellcheck 2>/dev/null || true
        ;;
esac

echo "✅ Development tools installed"
