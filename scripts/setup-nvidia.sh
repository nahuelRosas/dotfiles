#!/bin/bash
# ==============================================================================
# NVIDIA GPU Driver Setup (Multi-distro: Fedora, Ubuntu)
# ==============================================================================
set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

if ! check_internet; then
    echo "✅ NVIDIA driver setup skipped (no internet)"
    exit 0
fi

# Skip on WSL (WSL uses Windows GPU drivers via passthrough)
if is_wsl; then
    print_warning "NVIDIA drivers skipped on WSL"
    print_warning "WSL2 uses Windows NVIDIA drivers automatically via GPU passthrough"
    print_warning "Install NVIDIA drivers on Windows, not in WSL"
    exit 0
fi

echo "🎮 Setting up NVIDIA drivers..."
print_success "Detected: $DISTRO"

# Check if NVIDIA GPU is present
if ! lspci 2>/dev/null | grep -qi nvidia; then
    echo "  No NVIDIA GPU detected. Skipping..."
    exit 0
fi

GPU_INFO=$(lspci | grep -i nvidia | head -1)
echo "  Detected: $GPU_INFO"

# ==============================================================================
# Fedora NVIDIA Installation
# ==============================================================================
install_nvidia_fedora() {
    local FEDORA_VERSION=$(rpm -E %fedora)
    
    # Check if already installed
    if rpm -q akmod-nvidia &>/dev/null; then
        if [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
            print_success "NVIDIA drivers already installed"
            if lsmod | grep -q nvidia; then
                echo "  Driver version: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo 'unknown')"
            else
                print_warning "Driver installed but not loaded. A reboot may be required."
            fi
            return 0
        fi
    fi
    
    # Enable RPM Fusion repositories
    echo "  Enabling RPM Fusion repositories..."
    if ! rpm -q rpmfusion-free-release &>/dev/null; then
        sudo dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" 2>/dev/null || true
    fi
    if ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
        sudo dnf install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm" 2>/dev/null || true
    fi
    
    sudo dnf makecache --refresh 2>/dev/null || true
    
    # Install NVIDIA drivers
    echo "  Installing NVIDIA akmod drivers..."
    sudo dnf install -y akmod-nvidia 2>/dev/null || {
        print_error "Failed to install akmod-nvidia"
        return 1
    }
    
    # CUDA support
    echo "  Installing NVIDIA CUDA support..."
    sudo dnf install -y xorg-x11-drv-nvidia-cuda 2>/dev/null || true
    
    # Wayland support
    echo "  Configuring Wayland support..."
    sudo dnf install -y xorg-x11-drv-nvidia-power 2>/dev/null || true
    
    # Build kernel module
    echo "  Building kernel module (this may take a few minutes)..."
    sudo akmods --force 2>/dev/null
    sudo dracut --force 2>/dev/null
    
    print_success "NVIDIA driver packages installed"
    print_warning "A REBOOT is required to load the NVIDIA driver"
}

# ==============================================================================
# Ubuntu NVIDIA Installation
# ==============================================================================
install_nvidia_ubuntu() {
    # Check if already installed
    if dpkg -l nvidia-driver-* 2>/dev/null | grep -q "^ii"; then
        if [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
            print_success "NVIDIA drivers already installed"
            if command -v nvidia-smi &>/dev/null; then
                echo "  Driver version: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo 'unknown')"
            fi
            return 0
        fi
    fi
    
    # Install ubuntu-drivers-common
    sudo apt update
    sudo apt install -y ubuntu-drivers-common
    
    # Auto-detect and install recommended driver
    echo "  Detecting recommended NVIDIA driver..."
    local recommended=$(ubuntu-drivers devices 2>/dev/null | grep "recommended" | awk '{print $3}')
    
    if [[ -n "$recommended" ]]; then
        echo "  Installing recommended driver: $recommended"
        sudo apt install -y "$recommended" 2>/dev/null || {
            print_warning "Failed to install $recommended, trying alternative..."
            sudo ubuntu-drivers autoinstall 2>/dev/null || print_error "NVIDIA driver installation failed"
        }
    else
        echo "  Auto-installing drivers..."
        sudo ubuntu-drivers autoinstall 2>/dev/null || print_error "NVIDIA driver installation failed"
    fi
    
    print_success "NVIDIA driver packages installed"
    print_warning "A REBOOT is required to load the NVIDIA driver"
}

# ==============================================================================
# Main
# ==============================================================================
case "$DISTRO" in
    fedora)
        install_nvidia_fedora
        ;;
    ubuntu|debian)
        install_nvidia_ubuntu
        ;;
    arch)
        echo "  Installing NVIDIA drivers via pacman..."
        sudo pacman -S --noconfirm nvidia nvidia-utils nvidia-settings 2>/dev/null || true
        print_success "NVIDIA drivers installed"
        print_warning "A REBOOT is required"
        ;;
    *)
        print_error "NVIDIA driver installation not supported on $DISTRO"
        exit 1
        ;;
esac

echo ""
echo "After rebooting, verify with: nvidia-smi"
