#!/bin/bash
# ==============================================================================
# Flutter SDK Setup with Android and Web Support
# Note: iOS is not supported (requires macOS with Xcode)
# ==============================================================================
set -e

echo "🎯 Setting up Flutter SDK..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Paths
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/.flutter}"
ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"

# ==============================================================================
# Helper Functions
# ==============================================================================
print_step() {
    echo -e "${CYAN}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✔${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✖${NC} $1"
}

# ==============================================================================
# Detect OS and Package Manager
# ==============================================================================
detect_distro() {
    if [[ -f /etc/fedora-release ]]; then
        PKG_INSTALL="sudo dnf install -y"
        DISTRO="fedora"
    elif [[ -f /etc/debian_version ]]; then
        PKG_INSTALL="sudo apt install -y"
        DISTRO="debian"
    elif [[ -f /etc/arch-release ]]; then
        PKG_INSTALL="sudo pacman -S --noconfirm"
        DISTRO="arch"
    elif [[ "$(uname)" == "Darwin" ]]; then
        PKG_INSTALL="brew install"
        DISTRO="macos"
    else
        print_error "Unsupported operating system"
        exit 1
    fi
    print_success "Detected: $DISTRO"
}

# ==============================================================================
# Check Network Connectivity
# ==============================================================================
check_network() {
    print_step "Checking network connectivity..."
    
    if ! ping -c 1 -W 3 github.com &>/dev/null && ! curl -s --max-time 5 https://github.com &>/dev/null; then
        print_error "No internet connection to GitHub detected."
        print_warning "Flutter installation requires internet access."
        print_warning "Please check your network connection and try again."
        exit 1
    fi
    
    print_success "Network connectivity OK"
}

# ==============================================================================
# Install System Dependencies
# ==============================================================================
install_dependencies() {
    print_step "Installing system dependencies..."
    
    case $DISTRO in
        fedora)
            $PKG_INSTALL clang cmake ninja-build gtk3-devel libblkid-devel \
                lzma-sdk-devel curl git unzip xz zip mesa-libGLU-devel \
                libstdc++-static 2>/dev/null || true
            ;;
        debian)
            sudo apt update
            $PKG_INSTALL clang cmake ninja-build libgtk-3-dev liblzma-dev \
                curl git unzip xz-utils zip libglu1-mesa 2>/dev/null || true
            ;;
        arch)
            $PKG_INSTALL clang cmake ninja gtk3 lzma curl git unzip \
                xz zip glu 2>/dev/null || true
            ;;
        macos)
            # Xcode command line tools
            xcode-select --install 2>/dev/null || true
            ;;
    esac
    
    print_success "System dependencies installed"
}

# ==============================================================================
# Install Java (Required for Android SDK)
# ==============================================================================
install_java() {
    print_step "Checking Java installation..."
    
    if command -v java &>/dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n1 | awk -F '"' '{print $2}')
        print_success "Java already installed: $JAVA_VERSION"
        return
    fi
    
    print_step "Installing Java 17 (required for Android SDK)..."
    
    case $DISTRO in
        fedora)
            $PKG_INSTALL java-17-openjdk java-17-openjdk-devel
            ;;
        debian)
            $PKG_INSTALL openjdk-17-jdk
            ;;
        arch)
            $PKG_INSTALL jdk17-openjdk
            ;;
        macos)
            brew install openjdk@17
            ;;
    esac
    
    print_success "Java installed"
}

# ==============================================================================
# Install Flutter SDK
# ==============================================================================
install_flutter() {
    print_step "Installing Flutter SDK..."
    
    # Check if path exists (as file or directory)
    if [[ -e "$FLUTTER_HOME" ]]; then
        # If it's a valid Flutter installation (directory with .git)
        if [[ -d "$FLUTTER_HOME" ]] && [[ -d "$FLUTTER_HOME/.git" ]] && git -C "$FLUTTER_HOME" rev-parse --git-dir &>/dev/null; then
            print_step "Flutter already installed. Upgrading..."
            cd "$FLUTTER_HOME"
            git pull --quiet || true
            "$FLUTTER_HOME/bin/flutter" upgrade --quiet || true
            print_success "Flutter upgraded"
            return
        else
            # Path exists but is not a valid Flutter installation (could be file or corrupted dir)
            print_warning "Found invalid Flutter at $FLUTTER_HOME. Removing and reinstalling..."
            rm -rf "$FLUTTER_HOME"
        fi
    fi
    
    print_step "Cloning Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_HOME"
    
    print_success "Flutter SDK installed at $FLUTTER_HOME"
}

# ==============================================================================
# Install Android SDK (Command-line Tools)
# ==============================================================================
install_android_sdk() {
    print_step "Setting up Android SDK..."
    
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    
    if [[ -d "$ANDROID_HOME/cmdline-tools/latest" ]]; then
        print_success "Android command-line tools already installed"
    else
        print_step "Downloading Android command-line tools..."
        
        # Get the latest command-line tools
        local CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
        local TEMP_ZIP="/tmp/android-cmdline-tools.zip"
        
        curl -L -o "$TEMP_ZIP" "$CMDLINE_TOOLS_URL"
        
        print_step "Extracting command-line tools..."
        unzip -q "$TEMP_ZIP" -d "$ANDROID_HOME/cmdline-tools"
        mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
        rm "$TEMP_ZIP"
        
        print_success "Android command-line tools installed"
    fi
    
    # Set up environment
    export ANDROID_HOME="$ANDROID_HOME"
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
    
    # Install required SDK components
    print_step "Installing Android SDK components..."
    yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses 2>/dev/null || true
    
    "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
        "platform-tools" \
        "platforms;android-36" \
        "build-tools;36.0.0" \
        "emulator" 2>/dev/null || true
    
    print_success "Android SDK configured"
}

# ==============================================================================
# Install Chrome (for Web Development)
# ==============================================================================
install_chrome() {
    print_step "Checking Chrome installation..."
    
    if command -v google-chrome &>/dev/null || command -v google-chrome-stable &>/dev/null; then
        print_success "Chrome already installed"
        return
    fi
    
    if command -v chromium &>/dev/null || command -v chromium-browser &>/dev/null; then
        print_success "Chromium found (will be used for Flutter web)"
        return
    fi
    
    print_step "Installing Chrome/Chromium for Flutter web..."
    
    case $DISTRO in
        fedora)
            # Try Chromium first (available in repos)
            $PKG_INSTALL chromium 2>/dev/null || \
            flatpak install -y flathub com.google.Chrome 2>/dev/null || true
            ;;
        debian)
            $PKG_INSTALL chromium-browser 2>/dev/null || \
            $PKG_INSTALL chromium 2>/dev/null || true
            ;;
        arch)
            $PKG_INSTALL chromium 2>/dev/null || true
            ;;
        macos)
            brew install --cask google-chrome 2>/dev/null || true
            ;;
    esac
    
    print_success "Chrome/Chromium installed"
}

# ==============================================================================
# Configure Flutter
# ==============================================================================
configure_flutter() {
    print_step "Configuring Flutter..."
    
    export PATH="$FLUTTER_HOME/bin:$PATH"
    export ANDROID_HOME="$ANDROID_HOME"
    
    # Disable analytics and crash reporting
    "$FLUTTER_HOME/bin/flutter" config --no-analytics 2>/dev/null || true
    
    # Enable web support
    "$FLUTTER_HOME/bin/flutter" config --enable-web
    
    # Accept Android licenses
    print_step "Accepting Android licenses..."
    yes | "$FLUTTER_HOME/bin/flutter" doctor --android-licenses 2>/dev/null || true
    
    # Run flutter doctor to check configuration
    print_step "Running Flutter doctor..."
    "$FLUTTER_HOME/bin/flutter" doctor -v
    
    print_success "Flutter configured"
}

# ==============================================================================
# Create Environment File
# ==============================================================================
create_env_file() {
    print_step "Creating environment configuration..."
    
    local ENV_FILE="$HOME/.flutter_env"
    
    cat > "$ENV_FILE" << 'EOF'
# Flutter SDK Configuration
export FLUTTER_HOME="$HOME/.flutter"
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# Disable Flutter analytics
export FLUTTER_DISABLE_ANALYTICS=true
EOF
    
    print_success "Environment file created at $ENV_FILE"
}

# ==============================================================================
# Main
# ==============================================================================
main() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Flutter SDK Installation (Android + Web)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    detect_distro
    check_network
    install_dependencies
    install_java
    install_flutter
    install_android_sdk
    install_chrome
    configure_flutter
    create_env_file
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ Flutter setup complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Flutter: $("$FLUTTER_HOME/bin/flutter" --version | head -1)"
    echo -e "  Dart:    $("$FLUTTER_HOME/bin/dart" --version 2>&1)"
    echo ""
    echo -e "  ${YELLOW}Note: iOS development is not available (requires macOS with Xcode)${NC}"
    echo ""
    echo -e "  To reload your shell with Flutter:"
    echo -e "    ${CYAN}exec zsh${NC}  or  ${CYAN}source ~/.zshrc${NC}"
    echo ""
}

main "$@"
