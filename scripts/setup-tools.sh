#!/bin/bash
# ==============================================================================
# Development Tools Setup
# ==============================================================================
set -e

echo "🔧 Installing development tools..."

# ==============================================================================
# LAZYGIT (via Copr)
# ==============================================================================
echo "📦 Setting up Lazygit..."
if ! rpm -q lazygit &>/dev/null; then
    if [ ! -f /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:atim:lazygit.repo ]; then
        sudo dnf copr enable atim/lazygit -y 2>/dev/null || true
    fi
    sudo dnf install -y lazygit 2>/dev/null || echo "⚠️ Lazygit installation failed"
else
    echo "  Lazygit already installed"
fi

# ==============================================================================
# VSCODE
# ==============================================================================
echo "📦 Setting up VSCode..."
if ! command -v code &>/dev/null; then
    local vscode_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64"
    local vscode_rpm="/tmp/vscode.rpm"
    curl -L -o "$vscode_rpm" "$vscode_url" 2>/dev/null
    sudo dnf install -y "$vscode_rpm" 2>/dev/null || echo "⚠️ VSCode installation failed"
    rm -f "$vscode_rpm"
else
    echo "  VSCode already installed"
fi

# ==============================================================================
# CURSOR IDE
# ==============================================================================
echo "📦 Setting up Cursor..."
if ! command -v cursor &>/dev/null && ! rpm -q cursor &>/dev/null; then
    # Cursor doesn't have a stable download URL, check if available
    echo "  Cursor requires manual installation or visit: https://cursor.sh"
else
    echo "  Cursor already installed"
fi

# ==============================================================================
# BRAVE BROWSER
# ==============================================================================
echo "📦 Setting up Brave Browser..."
if ! command -v brave-browser &>/dev/null; then
    sudo dnf install -y dnf-plugins-core 2>/dev/null || true
    if [ ! -f /etc/yum.repos.d/brave-browser.repo ]; then
        sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo 2>/dev/null || true
        sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc 2>/dev/null || true
    fi
    sudo dnf install -y brave-browser 2>/dev/null || echo "⚠️ Brave installation failed"
else
    echo "  Brave already installed"
fi

# ==============================================================================
# CHROMEDRIVER
# ==============================================================================
echo "📦 Setting up Chromedriver..."
setup_chromedriver() {
    local installed_version=$(command -v chromedriver >/dev/null 2>&1 && chromedriver --version | awk '{print $2}' || echo "")
    local chromedriver_version=$(curl -sS https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_STABLE 2>/dev/null)
    
    if [[ "$installed_version" == "$chromedriver_version" ]]; then
        echo "  Chromedriver is up to date"
        return
    fi
    
    local download_dir="/tmp/chromedriver"
    local chromedriver_url="https://storage.googleapis.com/chrome-for-testing-public/$chromedriver_version/linux64/chromedriver-linux64.zip"
    
    mkdir -p "$download_dir"
    cd "$download_dir"
    
    curl -L -o chromedriver.zip "$chromedriver_url" 2>/dev/null
    
    if file chromedriver.zip | grep -q "Zip archive"; then
        unzip -o chromedriver.zip -d "$download_dir" 2>/dev/null
        sudo mv chromedriver-linux64/chromedriver /usr/local/bin/ 2>/dev/null
        sudo chmod +x /usr/local/bin/chromedriver
        echo "  Chromedriver $chromedriver_version installed"
    else
        echo "  ⚠️ Chromedriver download failed"
    fi
    
    cd -
    rm -rf "$download_dir"
}

setup_chromedriver

# ==============================================================================
# ADDITIONAL TOOLS (from dnf)
# ==============================================================================
TOOLS=(
    "neovim"
    "tmux"
    "shellcheck"
    "gh"  # GitHub CLI
)

echo "📦 Installing additional tools..."
for tool in "${TOOLS[@]}"; do
    if ! rpm -q "$tool" &>/dev/null; then
        sudo dnf install -y "$tool" 2>/dev/null || echo "  Skipped: $tool"
    fi
done

echo "✅ Development tools installed"
