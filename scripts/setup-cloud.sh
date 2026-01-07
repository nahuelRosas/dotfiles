#!/bin/bash
# ==============================================================================
# Cloud CLI Tools Setup (Multi-distro: Fedora, Ubuntu/Debian, Arch, macOS)
# ==============================================================================

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

echo "☁️ Setting up Cloud CLI tools..."
print_success "Detected: $DISTRO $(is_wsl && echo '(WSL)')"

if ! check_internet; then
    echo "✅ Cloud CLI setup skipped (no internet)"
    exit 0
fi

# ==============================================================================
# AWS CLI v2 (Universal binary install)
# ==============================================================================
echo "📦 Setting up AWS CLI..."
setup_aws_cli() {
    if command -v aws &>/dev/null && [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
        echo "  AWS CLI already installed: $(aws --version 2>/dev/null | awk '{print $1}')"
        return 0
    fi
    
    echo "  Downloading AWS CLI v2..."
    local temp_dir="/tmp/awscli-$$"
    mkdir -p "$temp_dir"
    
    if curl -fsSL --connect-timeout 10 "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$temp_dir/awscliv2.zip" 2>/dev/null; then
        if file "$temp_dir/awscliv2.zip" | grep -q "Zip archive"; then
            unzip -o "$temp_dir/awscliv2.zip" -d "$temp_dir" 2>/dev/null
            if [[ "${FORCE_REINSTALL:-false}" == "true" ]]; then
                sudo "$temp_dir/aws/install" --update 2>/dev/null || sudo "$temp_dir/aws/install" 2>/dev/null
            else
                sudo "$temp_dir/aws/install" 2>/dev/null
            fi
            print_success "AWS CLI installed"
        else
            print_warning "AWS CLI download corrupted"
        fi
    else
        print_warning "AWS CLI download failed"
    fi
    
    rm -rf "$temp_dir"
}
setup_aws_cli || true

# ==============================================================================
# GOOGLE CLOUD SDK (gcloud)
# ==============================================================================
echo "📦 Setting up Google Cloud SDK..."
setup_gcloud() {
    if command -v gcloud &>/dev/null && [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
        echo "  Google Cloud SDK already installed"
        return 0
    fi
    
    case "$DISTRO" in
        fedora)
            if [ ! -f /etc/yum.repos.d/google-cloud-sdk.repo ]; then
                echo "  Adding Google Cloud repository..."
                sudo tee /etc/yum.repos.d/google-cloud-sdk.repo > /dev/null << 'EOF'
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
            fi
            sudo dnf install -y --skip-unavailable google-cloud-cli 2>/dev/null || print_warning "gcloud installation failed"
            ;;
        ubuntu|debian)
            if [ ! -f /etc/apt/sources.list.d/google-cloud-sdk.list ]; then
                echo "  Adding Google Cloud repository..."
                curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg 2>/dev/null || true
                echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
                sudo apt update
            fi
            sudo apt install -y google-cloud-cli 2>/dev/null || print_warning "gcloud installation failed"
            ;;
        arch)
            # Install from AUR or use the script
            curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz 2>/dev/null
            tar -xf google-cloud-cli-linux-x86_64.tar.gz -C "$HOME" 2>/dev/null
            "$HOME/google-cloud-sdk/install.sh" --quiet 2>/dev/null || true
            rm -f google-cloud-cli-linux-x86_64.tar.gz
            ;;
        macos)
            brew install google-cloud-sdk 2>/dev/null || true
            ;;
    esac
    
    print_success "Google Cloud SDK installed"
}
setup_gcloud || true

# ==============================================================================
# FIREBASE CLI (via npm - distro agnostic)
# ==============================================================================
echo "📦 Setting up Firebase CLI..."
setup_firebase() {
    if command -v firebase &>/dev/null && [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
        echo "  Firebase CLI already installed"
        return 0
    fi
    
    if command -v npm &>/dev/null; then
        npm install -g firebase-tools 2>/dev/null && print_success "Firebase CLI installed" || print_warning "Firebase CLI installation failed"
    else
        print_warning "npm not available, skipping Firebase CLI"
    fi
}
setup_firebase || true

# ==============================================================================
# TERRAFORM
# ==============================================================================
echo "📦 Setting up Terraform..."
setup_terraform() {
    if command -v terraform &>/dev/null && [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
        echo "  Terraform already installed"
        return 0
    fi
    
    case "$DISTRO" in
        fedora)
            if [ ! -f /etc/yum.repos.d/hashicorp.repo ]; then
                echo "  Adding HashiCorp repository..."
                local FEDORA_VERSION=$(rpm -E %fedora)
                if [[ "$FEDORA_VERSION" -ge 41 ]]; then
                    sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo 2>/dev/null || \
                    sudo curl -fsSL https://rpm.releases.hashicorp.com/fedora/hashicorp.repo -o /etc/yum.repos.d/hashicorp.repo 2>/dev/null
                else
                    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo 2>/dev/null
                fi
            fi
            sudo dnf install -y --skip-unavailable terraform 2>/dev/null || print_warning "Terraform installation failed"
            ;;
        ubuntu|debian)
            if [ ! -f /etc/apt/sources.list.d/hashicorp.list ]; then
                curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null || true
                echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
                sudo apt update
            fi
            sudo apt install -y terraform 2>/dev/null || print_warning "Terraform installation failed"
            ;;
        arch)
            sudo pacman -S --noconfirm terraform 2>/dev/null || true
            ;;
        macos)
            brew install terraform 2>/dev/null || true
            ;;
    esac
}
setup_terraform || true

# ==============================================================================
# KUBECTL
# ==============================================================================
echo "📦 Setting up kubectl..."
setup_kubectl() {
    if command -v kubectl &>/dev/null && [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
        echo "  kubectl already installed"
        return 0
    fi
    
    local version
    version=$(curl -fsSL --connect-timeout 10 https://dl.k8s.io/release/stable.txt 2>/dev/null)
    
    if [[ -n "$version" ]]; then
        echo "  Downloading kubectl $version..."
        if curl -fsSL --connect-timeout 10 "https://dl.k8s.io/release/$version/bin/linux/amd64/kubectl" -o /tmp/kubectl 2>/dev/null; then
            sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
            rm -f /tmp/kubectl
            print_success "kubectl installed"
        else
            print_warning "kubectl download failed"
        fi
    else
        print_warning "Could not fetch kubectl version"
    fi
}
setup_kubectl || true

# ==============================================================================
# HELM
# ==============================================================================
echo "📦 Setting up Helm..."
setup_helm() {
    if command -v helm &>/dev/null && [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
        echo "  Helm already installed"
        return 0
    fi
    
    echo "  Installing Helm..."
    curl -fsSL --connect-timeout 10 https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 2>/dev/null | bash 2>/dev/null && \
        print_success "Helm installed" || print_warning "Helm installation failed"
}
setup_helm || true

# ==============================================================================
# VERCEL CLI (via npm)
# ==============================================================================
echo "📦 Setting up Vercel CLI..."
if command -v npm &>/dev/null; then
    if command -v vercel &>/dev/null && [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
        echo "  Vercel CLI already installed"
    else
        npm install -g vercel 2>/dev/null && print_success "Vercel CLI installed" || print_warning "Vercel CLI installation failed"
    fi
fi

# ==============================================================================
# NETLIFY CLI (via npm)
# ==============================================================================
echo "📦 Setting up Netlify CLI..."
if command -v npm &>/dev/null; then
    if command -v netlify &>/dev/null && [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
        echo "  Netlify CLI already installed"
    else
        npm install -g netlify-cli 2>/dev/null && print_success "Netlify CLI installed" || print_warning "Netlify CLI installation failed"
    fi
fi

echo "✅ Cloud CLI tools setup complete"
