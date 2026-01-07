#!/bin/bash
# ==============================================================================
# Development Tools Setup
# ==============================================================================

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
    echo "  ⚠️  This script requires internet to download tools."
    return 1
}

if ! check_internet; then
    echo "✅ Development tools setup skipped (no internet)"
    exit 0
fi

echo "🔧 Installing development tools..."

# Detect Fedora version for dnf5 compatibility
FEDORA_VERSION=$(rpm -E %fedora)

# Check if reinstall mode
REINSTALL_FLAG=""
if [[ "${FORCE_REINSTALL:-false}" == "true" ]]; then
    REINSTALL_FLAG="--reinstall"
fi

# Helper function to add repo (works with dnf4 and dnf5)
add_repo() {
    local repo_url="$1"
    local repo_file="$2"
    
    if [[ "$FEDORA_VERSION" -ge 41 ]]; then
        # dnf5 syntax
        sudo dnf config-manager addrepo --from-repofile="$repo_url" 2>/dev/null || \
        sudo curl -fsSL "$repo_url" -o "$repo_file" 2>/dev/null || true
    else
        # Legacy dnf4 syntax
        sudo dnf config-manager --add-repo "$repo_url" 2>/dev/null || true
    fi
}

# ==============================================================================
# LAZYGIT (Binary install - more reliable than Copr)
# ==============================================================================
echo "📦 Setting up Lazygit..."
setup_lazygit() {
    if [[ "${FORCE_REINSTALL:-false}" != "true" ]] && command -v lazygit &>/dev/null; then
        echo "  Lazygit already installed: $(lazygit --version 2>/dev/null | head -1)"
        return 0
    fi
    
    # Get latest version
    local version
    version=$(curl -s --connect-timeout 10 "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" 2>/dev/null | jq -r '.tag_name' 2>/dev/null | sed 's/^v//')
    
    if [[ -z "$version" || "$version" == "null" ]]; then
        echo "  ⚠️ Could not fetch Lazygit version. Trying dnf..."
        sudo dnf install -y lazygit 2>/dev/null || echo "  ⚠️ Lazygit installation failed"
        return 0
    fi
    
    echo "  Downloading Lazygit v$version..."
    local download_url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_x86_64.tar.gz"
    local temp_dir="/tmp/lazygit-$$"
    
    mkdir -p "$temp_dir"
    if curl -fsSL --connect-timeout 10 "$download_url" 2>/dev/null | tar xz -C "$temp_dir" 2>/dev/null; then
        sudo mv "$temp_dir/lazygit" /usr/local/bin/
        sudo chmod +x /usr/local/bin/lazygit
        echo "  ✅ Lazygit v$version installed"
    else
        echo "  ⚠️ Lazygit download failed"
    fi
    rm -rf "$temp_dir"
}
setup_lazygit || true

# ==============================================================================
# VSCODE
# ==============================================================================
echo "📦 Setting up VSCode..."
if [[ "${FORCE_REINSTALL:-false}" == "true" ]] || ! command -v code &>/dev/null; then
    vscode_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64"
    vscode_rpm="/tmp/vscode.rpm"
    echo "  Downloading VSCode..."
    if curl -L --connect-timeout 10 -o "$vscode_rpm" "$vscode_url" 2>/dev/null; then
        sudo dnf install -y "$vscode_rpm" 2>/dev/null || echo "⚠️ VSCode installation failed"
    else
        echo "  ⚠️ VSCode download failed"
    fi
    rm -f "$vscode_rpm"
else
    echo "  VSCode already installed"
fi

# ==============================================================================
# CURSOR IDE
# ==============================================================================
echo "📦 Setting up Cursor..."
if ! command -v cursor &>/dev/null && ! rpm -q cursor &>/dev/null; then
    echo "  Cursor requires manual installation or visit: https://cursor.sh"
else
    echo "  Cursor already installed"
fi

# ==============================================================================
# BRAVE BROWSER
# ==============================================================================
echo "📦 Setting up Brave Browser..."
if [[ "${FORCE_REINSTALL:-false}" == "true" ]] || ! command -v brave-browser &>/dev/null; then
    if [ ! -f /etc/yum.repos.d/brave-browser.repo ]; then
        add_repo "https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo" "/etc/yum.repos.d/brave-browser.repo"
        sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc 2>/dev/null || true
    fi
    sudo dnf install -y brave-browser 2>/dev/null || echo "⚠️ Brave installation failed"
else
    echo "  Brave already installed"
fi

# ==============================================================================
# CHROMEDRIVER (Disabled - Google changed their API and it's unreliable)
# ==============================================================================
echo "📦 Setting up Chromedriver..."
setup_chromedriver() {
    # Skip if already installed and not forcing reinstall
    if command -v chromedriver &>/dev/null && [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
        echo "  Chromedriver already installed: $(chromedriver --version 2>/dev/null | awk '{print $2}')"
        return 0
    fi
    
    # Try to install from dnf first (more reliable)
    if sudo dnf install -y --skip-unavailable chromedriver 2>/dev/null; then
        echo "  ✅ Chromedriver installed from repository"
        return 0
    fi
    
    echo "  ⚠️ Chromedriver not available in repositories. Install manually if needed."
    echo "     Visit: https://googlechromelabs.github.io/chrome-for-testing/"
}
setup_chromedriver || true

# ==============================================================================
# GITHUB CLI
# ==============================================================================
echo "📦 Setting up GitHub CLI..."
if [[ "${FORCE_REINSTALL:-false}" == "true" ]] || ! command -v gh &>/dev/null; then
    sudo dnf install -y --skip-unavailable gh 2>/dev/null || echo "  Skipped: gh"
else
    echo "  GitHub CLI already installed"
fi

# ==============================================================================
# ADDITIONAL TOOLS (from dnf)
# ==============================================================================
TOOLS=(
    "neovim"
    "tmux"
    "shellcheck"
)

echo "📦 Installing additional tools..."
for tool in "${TOOLS[@]}"; do
    if [[ "${FORCE_REINSTALL:-false}" == "true" ]] || ! rpm -q "$tool" &>/dev/null; then
        sudo dnf install -y --skip-unavailable "$tool" 2>/dev/null || echo "  Skipped: $tool"
    fi
done

echo "✅ Development tools installed"
