#!/bin/bash
# ==============================================================================
# Docker Setup for Fedora
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
    echo "  ⚠️  This script requires internet to download Docker."
    return 1
}

if ! check_internet; then
    echo "✅ Docker setup skipped (no internet)"
    exit 0
fi

echo "🐳 Setting up Docker..."

# Detect Fedora version for dnf5 compatibility
FEDORA_VERSION=$(rpm -E %fedora)

# Add Docker repository
if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
    echo "  Adding Docker repository..."
    
    # Fedora 41+ uses dnf5 with different syntax
    if [[ "$FEDORA_VERSION" -ge 41 ]]; then
        # Use dnf5 config-manager addrepo syntax
        sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo 2>/dev/null || \
        # Fallback: download repo file directly
        sudo curl -fsSL https://download.docker.com/linux/fedora/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo
    else
        # Legacy dnf4 syntax
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    fi
fi

# Docker packages
DOCKER_PACKAGES=(
    "docker-ce"
    "docker-ce-cli"
    "containerd.io"
    "docker-buildx-plugin"
    "docker-compose-plugin"
)

# Install packages
echo "  Installing Docker packages..."
for pkg in "${DOCKER_PACKAGES[@]}"; do
    if ! rpm -q "$pkg" &>/dev/null; then
        sudo dnf install -y "$pkg" 2>/dev/null || echo "    ⚠️ Failed to install $pkg"
    else
        echo "    $pkg already installed"
    fi
done

# Start and enable Docker service
echo "  Configuring Docker service..."
if ! systemctl is-active --quiet docker; then
    sudo systemctl start docker
fi

if ! systemctl is-enabled --quiet docker; then
    sudo systemctl enable docker
fi

# Add user to docker group
if ! groups "$USER" | grep -q docker; then
    echo "  Adding $USER to docker group..."
    sudo usermod -aG docker "$USER"
    echo "  ⚠️ You need to log out and back in for docker group to take effect"
fi

# Configure Docker daemon (optional optimizations)
DOCKER_DAEMON_CONFIG="/etc/docker/daemon.json"
if [ ! -f "$DOCKER_DAEMON_CONFIG" ]; then
    echo "  Configuring Docker daemon..."
    sudo tee "$DOCKER_DAEMON_CONFIG" > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "features": {
    "buildkit": true
  }
}
EOF
    sudo systemctl restart docker
fi

# Verify installation
if docker --version &>/dev/null; then
    echo "✅ Docker installed: $(docker --version)"
else
    echo "⚠️ Docker installation may have issues"
fi

if docker compose version &>/dev/null; then
    echo "✅ Docker Compose installed: $(docker compose version --short)"
fi
