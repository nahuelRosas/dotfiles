#!/bin/bash
# ==============================================================================
# Development Tools Setup (Multi-distro: Fedora, Ubuntu/Debian, Arch)
# Interactive version - asks before installing (default: no)
# ==============================================================================

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

echo "🔧 Development Tools Setup"
print_success "Detected: $DISTRO $(is_wsl && echo '(WSL)')"

if ! check_internet; then
    echo "✅ Development tools setup skipped (no internet)"
    exit 0
fi

echo ""
echo "Select which development tools to install:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# LAZYGIT
# ==============================================================================
if check_and_ask "Lazygit (Git TUI)" "lazygit" "sudo rm -f /usr/local/bin/lazygit"; then
    echo "📦 Installing Lazygit..."
    
    version=$(curl -s --connect-timeout 10 "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" 2>/dev/null | jq -r '.tag_name' 2>/dev/null | sed 's/^v//')
    
    if [[ -n "$version" && "$version" != "null" ]]; then
        echo "  Downloading Lazygit v$version..."
        download_url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_x86_64.tar.gz"
        temp_dir="/tmp/lazygit-$$"
        
        mkdir -p "$temp_dir"
        if curl -fsSL --connect-timeout 10 "$download_url" 2>/dev/null | tar xz -C "$temp_dir" 2>/dev/null; then
            sudo mv "$temp_dir/lazygit" /usr/local/bin/
            sudo chmod +x /usr/local/bin/lazygit
            print_success "Lazygit v$version installed"
        else
            print_warning "Lazygit download failed"
        fi
        rm -rf "$temp_dir"
    else
        print_warning "Could not fetch Lazygit version"
    fi
fi

# ==============================================================================
# VSCODE (skip on WSL)
# ==============================================================================
if ! is_wsl; then
    if check_and_ask "Visual Studio Code" "code" "pkg_uninstall code"; then
        echo "📦 Installing VSCode..."
        
        case "$DISTRO" in
            fedora)
                vscode_rpm="/tmp/vscode.rpm"
                echo "  Downloading VSCode..."
                if curl -L --connect-timeout 10 -o "$vscode_rpm" "https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64" 2>/dev/null; then
                    sudo dnf install -y "$vscode_rpm" 2>/dev/null && print_success "VSCode installed" || print_warning "VSCode installation failed"
                fi
                rm -f "$vscode_rpm"
                ;;
            ubuntu|debian)
                if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
                    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg 2>/dev/null || true
                    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
                    sudo apt update
                fi
                sudo apt install -y code 2>/dev/null && print_success "VSCode installed" || print_warning "VSCode installation failed"
                ;;
            arch)
                print_warning "VSCode: Install via AUR (yay -S visual-studio-code-bin)"
                ;;
        esac
    fi
else
    echo "  ℹ️  VSCode: Use Windows VSCode with Remote-WSL extension"
fi

# ==============================================================================
# BRAVE BROWSER (skip on WSL)
# ==============================================================================
if ! is_wsl; then
    if check_and_ask "Brave Browser" "brave-browser" "pkg_uninstall brave-browser"; then
        echo "📦 Installing Brave Browser..."
        
        case "$DISTRO" in
            fedora)
                if [ ! -f /etc/yum.repos.d/brave-browser.repo ]; then
                    sudo curl -fsSL https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo -o /etc/yum.repos.d/brave-browser.repo 2>/dev/null || true
                    sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc 2>/dev/null || true
                fi
                sudo dnf install -y brave-browser 2>/dev/null && print_success "Brave installed" || print_warning "Brave installation failed"
                ;;
            ubuntu|debian)
                if [ ! -f /etc/apt/sources.list.d/brave-browser.list ]; then
                    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg 2>/dev/null || true
                    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser.list > /dev/null
                    sudo apt update
                fi
                sudo apt install -y brave-browser 2>/dev/null && print_success "Brave installed" || print_warning "Brave installation failed"
                ;;
            arch)
                print_warning "Brave: Install via AUR (yay -S brave-bin)"
                ;;
        esac
    fi
else
    echo "  ℹ️  Brave Browser: Use Windows browser"
fi

# ==============================================================================
# GITHUB CLI
# ==============================================================================
if check_and_ask "GitHub CLI (gh)" "gh" "pkg_uninstall gh"; then
    echo "📦 Installing GitHub CLI..."
    
    case "$DISTRO" in
        fedora)
            sudo dnf install -y --skip-unavailable gh 2>/dev/null && print_success "gh installed" || print_warning "gh installation failed"
            ;;
        ubuntu|debian)
            if [ ! -f /etc/apt/sources.list.d/github-cli.list ]; then
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null || true
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                sudo apt update
            fi
            sudo apt install -y gh 2>/dev/null && print_success "gh installed" || print_warning "gh installation failed"
            ;;
        arch)
            sudo pacman -S --noconfirm github-cli 2>/dev/null && print_success "gh installed" || print_warning "gh installation failed"
            ;;
    esac
fi

# ==============================================================================
# NEOVIM
# ==============================================================================
if check_and_ask "Neovim" "nvim" "pkg_uninstall neovim"; then
    echo "📦 Installing Neovim..."
    pkg_install neovim && print_success "Neovim installed" || print_warning "Neovim installation failed"
fi

# ==============================================================================
# TMUX
# ==============================================================================
if check_and_ask "Tmux" "tmux" "pkg_uninstall tmux"; then
    echo "📦 Installing Tmux..."
    pkg_install tmux && print_success "Tmux installed" || print_warning "Tmux installation failed"
fi

# ==============================================================================
# SHELLCHECK
# ==============================================================================
if check_and_ask "ShellCheck (shell script linter)" "shellcheck" "pkg_uninstall shellcheck"; then
    echo "📦 Installing ShellCheck..."
    pkg_install shellcheck && print_success "ShellCheck installed" || print_warning "ShellCheck installation failed"
fi

echo ""
echo "✅ Development tools setup complete"
