#!/bin/bash
# ==============================================================================
# NVIDIA GPU Driver Setup for Fedora
# ==============================================================================
set -e

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
    echo "  ⚠️  This script requires internet to download NVIDIA drivers."
    return 1
}

if ! check_internet; then
    echo "✅ NVIDIA driver setup skipped (no internet)"
    exit 0
fi

echo "🎮 Setting up NVIDIA drivers..."

# Check if NVIDIA GPU is present
if ! lspci 2>/dev/null | grep -qi nvidia; then
    echo "  No NVIDIA GPU detected. Skipping..."
    exit 0
fi

# Get GPU info
GPU_INFO=$(lspci | grep -i nvidia | head -1)
echo "  Detected: $GPU_INFO"

# Detect Fedora version
FEDORA_VERSION=$(rpm -E %fedora)

# Check if drivers are already installed
if rpm -q akmod-nvidia &>/dev/null; then
    if [[ "${FORCE_REINSTALL:-false}" == "true" ]]; then
        echo "  Reinstalling NVIDIA drivers..."
    else
        echo "✅ NVIDIA drivers already installed"
        # Only try nvidia-smi if driver is loaded (after reboot)
        if lsmod | grep -q nvidia; then
            echo "  Driver version: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo 'unknown')"
        else
            echo "  ⚠️  Driver installed but not loaded. A reboot may be required."
        fi
        exit 0
    fi
fi

# Enable RPM Fusion Free and Non-Free repositories
echo "  Enabling RPM Fusion repositories..."
if ! rpm -q rpmfusion-free-release &>/dev/null; then
    sudo dnf install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
        2>/dev/null || true
fi

if ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
    sudo dnf install -y \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm" \
        2>/dev/null || true
fi

# Update package cache
echo "  Updating package cache..."
sudo dnf makecache --refresh 2>/dev/null || true

# Install NVIDIA drivers
echo "  Installing NVIDIA akmod drivers..."
sudo dnf install -y akmod-nvidia 2>/dev/null || {
    echo "  ⚠️ Failed to install akmod-nvidia"
    exit 1
}

# Install CUDA support (optional but useful)
echo "  Installing NVIDIA CUDA support..."
sudo dnf install -y xorg-x11-drv-nvidia-cuda 2>/dev/null || true

# For Wayland support
echo "  Configuring Wayland support..."
sudo dnf install -y xorg-x11-drv-nvidia-power 2>/dev/null || true

# Enable nvidia-powerd for laptops
if [[ -f /sys/class/dmi/id/chassis_type ]]; then
    chassis=$(cat /sys/class/dmi/id/chassis_type)
    # Laptop chassis types: 9, 10, 14
    if [[ "$chassis" =~ ^(9|10|14)$ ]]; then
        echo "  Enabling NVIDIA power management for laptop..."
        sudo systemctl enable nvidia-powerd 2>/dev/null || true
    fi
fi

# Wait for kernel module to build
echo "  Waiting for kernel module build..."
echo "  (This may take a few minutes...)"
sudo akmods --force 2>/dev/null
sudo dracut --force 2>/dev/null

# Verify package installation (don't run nvidia-smi before reboot - it will fail)
echo ""
if rpm -q akmod-nvidia &>/dev/null; then
    echo "✅ NVIDIA driver packages installed successfully!"
    echo ""
    echo "  📋 Installed packages:"
    rpm -qa | grep -E '^(akmod-nvidia|xorg-x11-drv-nvidia)' | sed 's/^/     • /'
    echo ""
    echo "  ⚠️  A REBOOT is required to load the NVIDIA driver."
    echo "  After rebooting, run 'nvidia-smi' to verify the installation."
else
    echo "❌ NVIDIA driver installation may have failed"
    echo "  Please check the output above for errors."
fi
