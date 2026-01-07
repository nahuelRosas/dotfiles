#!/bin/bash
# ==============================================================================
# Docker Setup (Multi-distro: Fedora, Ubuntu/Debian)
# ==============================================================================
set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

if ! check_internet; then
    echo "✅ Docker setup skipped (no internet)"
    exit 0
fi

echo "🐳 Setting up Docker..."
print_success "Detected: $DISTRO $(is_wsl && echo '(WSL)')"

# Docker packages (same names on both Fedora and Ubuntu)
DOCKER_PACKAGES=(
    "docker-ce"
    "docker-ce-cli"
    "containerd.io"
    "docker-buildx-plugin"
    "docker-compose-plugin"
)

# ==============================================================================
# Add Docker Repository
# ==============================================================================
setup_docker_repo_fedora() {
    if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
        echo "  Adding Docker repository..."
        local FEDORA_VERSION=$(rpm -E %fedora)
        
        if [[ "$FEDORA_VERSION" -ge 41 ]]; then
            sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo 2>/dev/null || \
            sudo curl -fsSL https://download.docker.com/linux/fedora/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo
        else
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo 2>/dev/null || true
        fi
    fi
}

setup_docker_repo_ubuntu() {
    if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
        echo "  Adding Docker repository..."
        
        # Install prerequisites
        sudo apt update
        sudo apt install -y ca-certificates curl gnupg lsb-release
        
        # Add Docker's official GPG key
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        
        # Add repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        sudo apt update
    fi
}

# ==============================================================================
# Install Docker
# ==============================================================================
install_docker_fedora() {
    setup_docker_repo_fedora
    
    echo "  Installing Docker packages..."
    for pkg in "${DOCKER_PACKAGES[@]}"; do
        if ! rpm -q "$pkg" &>/dev/null; then
            sudo dnf install -y "$pkg" 2>/dev/null || print_warning "Failed to install $pkg"
        else
            echo "    $pkg already installed"
        fi
    done
}

install_docker_ubuntu() {
    setup_docker_repo_ubuntu
    
    echo "  Installing Docker packages..."
    sudo apt install -y "${DOCKER_PACKAGES[@]}" 2>/dev/null || {
        for pkg in "${DOCKER_PACKAGES[@]}"; do
            sudo apt install -y "$pkg" 2>/dev/null || print_warning "Failed to install $pkg"
        done
    }
}

# ==============================================================================
# Configure Docker Service
# ==============================================================================
configure_docker_service() {
    # WSL note: Docker Desktop for Windows is typically used instead
    if is_wsl; then
        print_warning "On WSL, consider using Docker Desktop for Windows instead"
        print_warning "If using native Docker in WSL2, ensure systemd is enabled"
    fi
    
    # Start and enable Docker service (if systemd is available)
    if command -v systemctl &>/dev/null; then
        echo "  Configuring Docker service..."
        if ! systemctl is-active --quiet docker 2>/dev/null; then
            sudo systemctl start docker 2>/dev/null || true
        fi
        if ! systemctl is-enabled --quiet docker 2>/dev/null; then
            sudo systemctl enable docker 2>/dev/null || true
        fi
    fi
    
    # Add user to docker group
    if ! groups "$USER" | grep -q docker; then
        echo "  Adding $USER to docker group..."
        sudo usermod -aG docker "$USER"
        print_warning "You need to log out and back in for docker group to take effect"
    fi
}

# ==============================================================================
# Configure Docker Daemon
# ==============================================================================
configure_docker_daemon() {
    local DOCKER_DAEMON_CONFIG="/etc/docker/daemon.json"
    
    if [ ! -f "$DOCKER_DAEMON_CONFIG" ]; then
        echo "  Configuring Docker daemon..."
        sudo mkdir -p /etc/docker
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
        if command -v systemctl &>/dev/null; then
            sudo systemctl restart docker 2>/dev/null || true
        fi
    fi
}

# ==============================================================================
# Main
# ==============================================================================
case "$DISTRO" in
    fedora)
        install_docker_fedora
        ;;
    ubuntu|debian)
        install_docker_ubuntu
        ;;
    arch)
        sudo pacman -S --noconfirm docker docker-compose 2>/dev/null || true
        ;;
    macos)
        print_warning "On macOS, install Docker Desktop from https://www.docker.com/products/docker-desktop"
        exit 0
        ;;
    *)
        print_error "Unsupported distro: $DISTRO"
        exit 1
        ;;
esac

configure_docker_service
configure_docker_daemon

# Verify installation
if docker --version &>/dev/null; then
    echo "✅ Docker installed: $(docker --version)"
else
    print_warning "Docker installation may have issues"
fi

if docker compose version &>/dev/null 2>&1; then
    echo "✅ Docker Compose installed: $(docker compose version --short 2>/dev/null)"
fi
