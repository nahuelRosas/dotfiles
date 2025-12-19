#!/bin/bash
# ==============================================================================
# NVM + Node.js Setup
# ==============================================================================
set -e

echo "📦 Setting up NVM and Node.js..."

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# Get latest NVM version
echo "  Checking latest NVM version..."
LATEST_NVM=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r '.tag_name')

if [[ -z "$LATEST_NVM" ]] || [[ "$LATEST_NVM" == "null" ]]; then
    LATEST_NVM="v0.39.7"
    echo "  Using fallback version: $LATEST_NVM"
fi

# Install or update NVM
install_nvm() {
    echo "  Installing NVM $LATEST_NVM..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$LATEST_NVM/install.sh" 2>/dev/null | bash
}

if [ ! -d "$NVM_DIR" ]; then
    install_nvm
else
    # Check current version
    source "$NVM_DIR/nvm.sh" 2>/dev/null || true
    CURRENT_NVM=$(nvm --version 2>/dev/null || echo "0.0.0")
    
    if [[ "v$CURRENT_NVM" != "$LATEST_NVM" ]]; then
        echo "  Updating NVM from v$CURRENT_NVM to $LATEST_NVM..."
        install_nvm
    else
        echo "  NVM is up to date (v$CURRENT_NVM)"
    fi
fi

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install Node.js LTS
echo "  Installing Node.js LTS..."
NODE_VERSION="lts/*"

if ! nvm ls "$NODE_VERSION" &>/dev/null; then
    nvm install "$NODE_VERSION"
fi

nvm alias default "$NODE_VERSION"
nvm use default

echo "  Node.js version: $(node --version)"
echo "  npm version: $(npm --version)"

# Install PNPM
echo "  Installing pnpm..."
if ! command -v pnpm &>/dev/null; then
    npm install -g pnpm@latest
else
    echo "  pnpm already installed: $(pnpm --version)"
fi

# Install Yarn (optional)
echo "  Installing yarn..."
if ! command -v yarn &>/dev/null; then
    npm install -g yarn
else
    echo "  yarn already installed: $(yarn --version)"
fi

# Install useful global packages
echo "  Installing global npm packages..."
GLOBAL_PACKAGES=(
    "typescript"
    "ts-node"
    "nodemon"
    "npm-check-updates"
    "serve"
)

for pkg in "${GLOBAL_PACKAGES[@]}"; do
    if ! npm list -g "$pkg" &>/dev/null; then
        npm install -g "$pkg" 2>/dev/null || echo "    Skipped: $pkg"
    fi
done

echo "✅ NVM and Node.js setup complete"
echo "   Node: $(node --version)"
echo "   npm: $(npm --version)"
echo "   pnpm: $(pnpm --version 2>/dev/null || echo 'not installed')"
