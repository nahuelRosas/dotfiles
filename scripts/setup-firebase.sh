#!/bin/bash
# ==============================================================================
# Firebase CLI Setup
# ==============================================================================

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

echo "🔥 Setting up Firebase CLI..."
print_success "Detected: $DISTRO $(is_wsl && echo '(WSL)')"

if ! check_internet; then
    echo "✅ Firebase CLI setup skipped (no internet)"
    exit 0
fi

# ==============================================================================
# FIREBASE CLI
# ==============================================================================
setup_firebase() {
    if command -v firebase &>/dev/null && [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
        echo "  Firebase CLI already installed: $(firebase --version 2>/dev/null)"
        return 0
    fi
    
    # Firebase CLI is installed via npm - use ensure_npm to load NVM if needed
    if ensure_npm; then
        echo "  Installing firebase-tools via npm..."
        run_npm install -g firebase-tools && \
            echo "  ✅ Firebase CLI installed: $(firebase --version 2>/dev/null)" || \
            echo "  ⚠️ Firebase CLI installation failed"
    else
        echo "  ⚠️ npm not available. Install Node.js first (make nvm)"
        echo "  Alternative: Install standalone binary..."
        
        # Fallback: Install standalone Firebase CLI binary
        local install_dir="$HOME/.local/bin"
        mkdir -p "$install_dir"
        
        if curl -sL https://firebase.tools | sed "s|/usr/local/bin|$install_dir|g" | bash 2>/dev/null; then
            echo "  ✅ Firebase CLI installed (standalone)"
        else
            echo "  ⚠️ Firebase CLI installation failed"
            return 1
        fi
    fi
}
setup_firebase || true

# ==============================================================================
# FIREBASE AUTHENTICATION (Interactive)
# ==============================================================================
configure_firebase_auth() {
    if [[ "${SKIP_FIREBASE_AUTH:-false}" == "true" ]]; then
        return 0
    fi
    
    if ! command -v firebase &>/dev/null; then
        return 0
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔐 Firebase CLI Authentication"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check if already authenticated
    if firebase projects:list &>/dev/null 2>&1; then
        echo "  ✅ Already authenticated with Firebase"
        return 0
    fi
    
    read -p "Authenticate with Firebase? [Y/n]: " auth_firebase
    auth_firebase=${auth_firebase:-Y}
    
    if [[ "$auth_firebase" =~ ^[Yy] ]]; then
        firebase login
    else
        echo "  ⏭️ Skipping Firebase authentication"
    fi
}

configure_firebase_auth

echo "✅ Firebase CLI setup complete"
