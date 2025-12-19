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
echo "  Fetching available Node.js LTS versions..."

# Get list of unique LTS names with their latest version (e.g., "Iron v20.10.0")
# We use awk to find the first occurrence of each LTS name (which is the latest version due to file ordering)
if command -v curl &>/dev/null; then
    available_lts=$(curl -s https://nodejs.org/dist/index.tab | awk -F'\t' '
        NR>1 && $10 != "-" {
            if (!seen[$10]++) {
                print $10 " (" $1 ")"
            }
        }
    ')
else
    # Fallback to nvm if curl is not available (less detailed)
    available_lts=$(nvm ls-remote --lts | grep 'LTS:' | sed 's/.*LTS: \([a-zA-Z]*\).*/\1/' | sort -u | tac)
fi

if [ -z "$available_lts" ]; then
    echo "  Could not fetch LTS versions. Falling back to default 'lts/*'."
    NODE_VERSION="lts/*"
else
    # Convert newline-separated string to array
    mapfile -t lts_array <<< "$available_lts"
    
    # Clean up empty lines if any (without splitting by space)
    temp_array=()
    for item in "${lts_array[@]}"; do
        if [[ -n "$item" ]]; then
            temp_array+=("$item")
        fi
    done
    lts_array=("${temp_array[@]}")
    
    echo "  Available LTS versions:"
    default_selection=""
    default_name_pref="Iron"
    
    for i in "${!lts_array[@]}"; do
        echo "    $((i+1))) ${lts_array[$i]}"
        # Check if this item matches the preferred default name
        if [[ "${lts_array[$i]}" == *"$default_name_pref"* ]]; then
            default_selection=$((i+1))
        fi
    done
    
    prompt_msg="  Select an LTS version to install (1-${#lts_array[@]})"
    if [ -n "$default_selection" ]; then
        prompt_msg="$prompt_msg [default: $default_selection (${lts_array[$((default_selection-1))]} )]: "
    else
        prompt_msg="$prompt_msg: "
    fi

    while true; do
        read -p "$prompt_msg" selection
        
        # Handle default selection
        if [ -z "$selection" ] && [ -n "$default_selection" ]; then
            selection=$default_selection
        fi

        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#lts_array[@]}" ]; then
            selected_entry="${lts_array[$((selection-1))]}"
            # Extract just the name (first word) for installation
            selected_name=$(echo "$selected_entry" | awk '{print $1}')
            
            # Convert to lowercase for nvm install lts/name
            NODE_VERSION="lts/$(echo "$selected_name" | tr '[:upper:]' '[:lower:]')"
            echo "  Selected: $selected_entry"
            break
        else
            echo "  Invalid selection. Please try again."
        fi
    done
fi

if ! nvm ls "$NODE_VERSION" &>/dev/null; then
    echo "  Installing $NODE_VERSION..."
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
