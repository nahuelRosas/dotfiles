#!/bin/bash
# ==============================================================================
# Cloud CLI Tools Setup (Multi-distro: Fedora, Ubuntu/Debian, Arch, macOS)
# Interactive version - asks before installing each tool (default: no)
# ==============================================================================

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

echo "☁️ Cloud CLI Tools Setup"
print_success "Detected: $DISTRO $(is_wsl && echo '(WSL)')"

if ! check_internet; then
    echo "✅ Cloud CLI setup skipped (no internet)"
    exit 0
fi

echo ""
echo "Select which cloud tools to install/manage:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ==============================================================================
# AWS CLI v2
# ==============================================================================
if check_and_ask "AWS CLI" "aws" "sudo rm -rf /usr/local/aws-cli && sudo rm -f /usr/local/bin/aws /usr/local/bin/aws_completer"; then
    echo "📦 Installing AWS CLI..."
    
    temp_dir="/tmp/awscli-$$"
    mkdir -p "$temp_dir"
    
    echo "  Downloading AWS CLI v2 (this may take a moment)..."
    if curl -fsSL --connect-timeout 30 --max-time 300 "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$temp_dir/awscliv2.zip" 2>/dev/null; then
        if file "$temp_dir/awscliv2.zip" | grep -q "Zip archive"; then
            echo "  Extracting..."
            unzip -q -o "$temp_dir/awscliv2.zip" -d "$temp_dir" 2>/dev/null
            echo "  Installing..."
            sudo "$temp_dir/aws/install" --update 2>/dev/null || sudo "$temp_dir/aws/install" 2>/dev/null
            print_success "AWS CLI installed"
        else
            print_warning "AWS CLI download corrupted"
        fi
    else
        print_warning "AWS CLI download failed (timeout)"
        echo "  Manual install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    fi
    
    rm -rf "$temp_dir"
fi

# ==============================================================================
# GOOGLE CLOUD SDK (gcloud)
# ==============================================================================
if check_and_ask "Google Cloud SDK (gcloud)" "gcloud" "pkg_uninstall google-cloud-cli"; then
    echo "📦 Installing Google Cloud SDK..."
    
    case "$DISTRO" in
        fedora)
            if [ ! -f /etc/yum.repos.d/google-cloud-sdk.repo ]; then
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
            sudo dnf install -y --skip-unavailable google-cloud-cli 2>/dev/null && print_success "gcloud installed" || print_warning "gcloud installation failed"
            ;;
        ubuntu|debian)
            if [ ! -f /etc/apt/sources.list.d/google-cloud-sdk.list ]; then
                curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg 2>/dev/null || true
                echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
                sudo apt update
            fi
            sudo apt install -y google-cloud-cli 2>/dev/null && print_success "gcloud installed" || print_warning "gcloud installation failed"
            ;;
        arch)
            curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz 2>/dev/null
            tar -xf google-cloud-cli-linux-x86_64.tar.gz -C "$HOME" 2>/dev/null
            "$HOME/google-cloud-sdk/install.sh" --quiet 2>/dev/null && print_success "gcloud installed" || print_warning "gcloud installation failed"
            rm -f google-cloud-cli-linux-x86_64.tar.gz
            ;;
        macos)
            brew install google-cloud-sdk 2>/dev/null && print_success "gcloud installed" || print_warning "gcloud installation failed"
            ;;
    esac
fi

# ==============================================================================


# ==============================================================================
# TERRAFORM
# ==============================================================================
if check_and_ask "Terraform" "terraform" "pkg_uninstall terraform"; then
    echo "📦 Installing Terraform..."
    
    case "$DISTRO" in
        fedora)
            if [ ! -f /etc/yum.repos.d/hashicorp.repo ]; then
                FEDORA_VERSION=$(rpm -E %fedora)
                if [[ "$FEDORA_VERSION" -ge 41 ]]; then
                    sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo 2>/dev/null || \
                    sudo curl -fsSL https://rpm.releases.hashicorp.com/fedora/hashicorp.repo -o /etc/yum.repos.d/hashicorp.repo 2>/dev/null
                else
                    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo 2>/dev/null
                fi
            fi
            sudo dnf install -y --skip-unavailable terraform 2>/dev/null && print_success "Terraform installed" || print_warning "Terraform installation failed"
            ;;
        ubuntu|debian)
            if [ ! -f /etc/apt/sources.list.d/hashicorp.list ]; then
                curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null || true
                echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
                sudo apt update
            fi
            sudo apt install -y terraform 2>/dev/null && print_success "Terraform installed" || print_warning "Terraform installation failed"
            ;;
        arch)
            sudo pacman -S --noconfirm terraform 2>/dev/null && print_success "Terraform installed" || print_warning "Terraform installation failed"
            ;;
        macos)
            brew install terraform 2>/dev/null && print_success "Terraform installed" || print_warning "Terraform installation failed"
            ;;
    esac
fi

# ==============================================================================
# KUBECTL
# ==============================================================================
if check_and_ask "kubectl (Kubernetes CLI)" "kubectl" "sudo rm -f /usr/local/bin/kubectl"; then
    echo "📦 Installing kubectl..."
    
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
fi

# ==============================================================================
# HELM
# ==============================================================================
if check_and_ask "Helm (Kubernetes package manager)" "helm" "sudo rm -f /usr/local/bin/helm"; then
    echo "📦 Installing Helm..."
    
    curl -fsSL --connect-timeout 10 https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 2>/dev/null | bash 2>/dev/null && \
        print_success "Helm installed" || print_warning "Helm installation failed"
fi

# ==============================================================================
# VERCEL CLI (via npm)
# ==============================================================================
if check_and_ask "Vercel CLI" "vercel" "npm_uninstall vercel"; then
    echo "📦 Installing Vercel CLI..."
    
    if ensure_npm; then
        run_npm install -g vercel 2>/dev/null && print_success "Vercel CLI installed" || print_warning "Vercel CLI installation failed"
    else
        print_warning "npm not available"
    fi
fi

# ==============================================================================
# NETLIFY CLI (via npm)
# ==============================================================================
if check_and_ask "Netlify CLI" "netlify" "npm_uninstall netlify-cli"; then
    echo "📦 Installing Netlify CLI..."
    
    if ensure_npm; then
        run_npm install -g netlify-cli 2>/dev/null && print_success "Netlify CLI installed" || print_warning "Netlify CLI installation failed"
    else
        print_warning "npm not available"
    fi
fi

echo ""
echo "✅ Cloud CLI tools setup complete"
