#!/bin/bash
# ==============================================================================
# Cloud CLI Tools Setup
# ==============================================================================
# Note: This script uses set +e to allow individual failures without stopping

echo "☁️ Setting up Cloud CLI tools..."

# Detect Fedora version
FEDORA_VERSION=$(rpm -E %fedora)

# Check internet connectivity (multiple methods for reliability)
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
    
    echo "  ⚠️ No internet connection detected. Skipping cloud CLI installation."
    return 1
}

if ! check_internet; then
    echo "✅ Cloud CLI setup skipped (no internet)"
    exit 0
fi

# ==============================================================================
# AWS CLI v2
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
            echo "  ✅ AWS CLI installed"
        else
            echo "  ⚠️ AWS CLI download corrupted"
        fi
    else
        echo "  ⚠️ AWS CLI download failed (network issue)"
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
    
    # Install via dnf if available
    if ! rpm -q google-cloud-cli &>/dev/null; then
        # Add Google Cloud repo
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
        
        sudo dnf install -y --skip-unavailable google-cloud-cli 2>/dev/null || {
            echo "  ⚠️ Google Cloud SDK installation failed"
            return 1
        }
    fi
    
    echo "  ✅ Google Cloud SDK installed"
}
setup_gcloud || true

# ==============================================================================
# FIREBASE CLI
# ==============================================================================
echo "📦 Setting up Firebase CLI..."
setup_firebase() {
    if command -v firebase &>/dev/null && [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
        echo "  Firebase CLI already installed"
        return 0
    fi
    
    # Firebase CLI is installed via npm
    if command -v npm &>/dev/null; then
        npm install -g firebase-tools 2>/dev/null && \
            echo "  ✅ Firebase CLI installed" || \
            echo "  ⚠️ Firebase CLI installation failed"
    else
        echo "  ⚠️ npm not available, skipping Firebase CLI"
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
    
    # Add HashiCorp repo
    if [ ! -f /etc/yum.repos.d/hashicorp.repo ]; then
        echo "  Adding HashiCorp repository..."
        if [[ "$FEDORA_VERSION" -ge 41 ]]; then
            sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo 2>/dev/null || \
            sudo curl -fsSL --connect-timeout 10 https://rpm.releases.hashicorp.com/fedora/hashicorp.repo -o /etc/yum.repos.d/hashicorp.repo 2>/dev/null
        else
            sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo 2>/dev/null
        fi
    fi
    
    sudo dnf install -y --skip-unavailable terraform 2>/dev/null && \
        echo "  ✅ Terraform installed" || \
        echo "  ⚠️ Terraform installation failed"
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
    
    # Get latest version
    local version
    version=$(curl -fsSL --connect-timeout 10 https://dl.k8s.io/release/stable.txt 2>/dev/null)
    
    if [[ -n "$version" ]]; then
        echo "  Downloading kubectl $version..."
        if curl -fsSL --connect-timeout 10 "https://dl.k8s.io/release/$version/bin/linux/amd64/kubectl" -o /tmp/kubectl 2>/dev/null; then
            sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
            rm -f /tmp/kubectl
            echo "  ✅ kubectl installed"
        else
            echo "  ⚠️ kubectl download failed"
        fi
    else
        echo "  ⚠️ Could not fetch kubectl version"
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
        echo "  ✅ Helm installed" || \
        echo "  ⚠️ Helm installation failed"
}
setup_helm || true

# ==============================================================================
# VERCEL CLI
# ==============================================================================
echo "📦 Setting up Vercel CLI..."
if command -v npm &>/dev/null; then
    if command -v vercel &>/dev/null && [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
        echo "  Vercel CLI already installed"
    else
        npm install -g vercel 2>/dev/null && \
            echo "  ✅ Vercel CLI installed" || \
            echo "  ⚠️ Vercel CLI installation failed"
    fi
fi

# ==============================================================================
# NETLIFY CLI
# ==============================================================================
echo "📦 Setting up Netlify CLI..."
if command -v npm &>/dev/null; then
    if command -v netlify &>/dev/null && [[ "${FORCE_REINSTALL:-false}" != "true" ]]; then
        echo "  Netlify CLI already installed"
    else
        npm install -g netlify-cli 2>/dev/null && \
            echo "  ✅ Netlify CLI installed" || \
            echo "  ⚠️ Netlify CLI installation failed"
    fi
fi

echo "✅ Cloud CLI tools setup complete"

# ==============================================================================
# CLOUD CLI AUTHENTICATION (Interactive)
# ==============================================================================
configure_cloud_auth() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔐 Cloud CLI Authentication"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Would you like to authenticate with installed cloud services?"
    echo "(You can skip any service you don't want to configure)"
    echo ""
    
    read -p "Proceed with authentication setup? [Y/n]: " do_auth
    do_auth=${do_auth:-Y}
    
    if [[ ! "$do_auth" =~ ^[Yy] ]]; then
        echo "⏭️ Skipping authentication setup"
        return 0
    fi
    
    # --- GitHub CLI ---
    if command -v gh &>/dev/null; then
        echo ""
        echo "📦 GitHub CLI (gh)"
        if gh auth status &>/dev/null 2>&1; then
            echo "  ✅ Already authenticated"
        else
            read -p "  Authenticate with GitHub? [Y/n]: " auth_gh
            auth_gh=${auth_gh:-Y}
            if [[ "$auth_gh" =~ ^[Yy] ]]; then
                gh auth login
            fi
        fi
    fi
    
    # --- Google Cloud ---
    if command -v gcloud &>/dev/null; then
        echo ""
        echo "📦 Google Cloud SDK (gcloud)"
        local gcloud_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
        if [[ -n "$gcloud_account" ]]; then
            echo "  ✅ Already authenticated as: $gcloud_account"
            read -p "  Re-authenticate or add another account? [y/N]: " reauth_gcloud
            if [[ "$reauth_gcloud" =~ ^[Yy] ]]; then
                gcloud auth login
            fi
        else
            read -p "  Authenticate with Google Cloud? [Y/n]: " auth_gcloud
            auth_gcloud=${auth_gcloud:-Y}
            if [[ "$auth_gcloud" =~ ^[Yy] ]]; then
                gcloud auth login
                # Also set up application default credentials
                read -p "  Also set up Application Default Credentials (for local dev)? [Y/n]: " adc_gcloud
                adc_gcloud=${adc_gcloud:-Y}
                if [[ "$adc_gcloud" =~ ^[Yy] ]]; then
                    gcloud auth application-default login
                fi
            fi
        fi
    fi
    
    # --- AWS CLI ---
    if command -v aws &>/dev/null; then
        echo ""
        echo "📦 AWS CLI"
        if aws sts get-caller-identity &>/dev/null 2>&1; then
            local aws_account=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null)
            echo "  ✅ Already authenticated (Account: $aws_account)"
        else
            read -p "  Configure AWS credentials? [Y/n]: " auth_aws
            auth_aws=${auth_aws:-Y}
            if [[ "$auth_aws" =~ ^[Yy] ]]; then
                echo ""
                echo "  Choose authentication method:"
                echo "    1) AWS SSO (recommended for organizations)"
                echo "    2) Access Key ID and Secret Access Key"
                echo "    3) Skip"
                echo ""
                read -p "  Select [1]: " aws_method
                aws_method=${aws_method:-1}
                
                case $aws_method in
                    1)
                        echo "  Starting AWS SSO configuration..."
                        aws configure sso
                        ;;
                    2)
                        echo "  Starting AWS credential configuration..."
                        aws configure
                        ;;
                    *)
                        echo "  ⏭️ Skipping AWS authentication"
                        ;;
                esac
            fi
        fi
    fi
    
    # --- Firebase CLI ---
    if command -v firebase &>/dev/null; then
        echo ""
        echo "📦 Firebase CLI"
        # Firebase doesn't have a simple status check, so we try listing projects
        if firebase projects:list &>/dev/null 2>&1; then
            echo "  ✅ Already authenticated"
        else
            read -p "  Authenticate with Firebase? [Y/n]: " auth_firebase
            auth_firebase=${auth_firebase:-Y}
            if [[ "$auth_firebase" =~ ^[Yy] ]]; then
                firebase login
            fi
        fi
    fi
    
    # --- Vercel CLI ---
    if command -v vercel &>/dev/null; then
        echo ""
        echo "📦 Vercel CLI"
        if vercel whoami &>/dev/null 2>&1; then
            local vercel_user=$(vercel whoami 2>/dev/null)
            echo "  ✅ Already authenticated as: $vercel_user"
        else
            read -p "  Authenticate with Vercel? [Y/n]: " auth_vercel
            auth_vercel=${auth_vercel:-Y}
            if [[ "$auth_vercel" =~ ^[Yy] ]]; then
                vercel login
            fi
        fi
    fi
    
    # --- Netlify CLI ---
    if command -v netlify &>/dev/null; then
        echo ""
        echo "📦 Netlify CLI"
        if netlify status &>/dev/null 2>&1; then
            echo "  ✅ Already authenticated"
        else
            read -p "  Authenticate with Netlify? [Y/n]: " auth_netlify
            auth_netlify=${auth_netlify:-Y}
            if [[ "$auth_netlify" =~ ^[Yy] ]]; then
                netlify login
            fi
        fi
    fi
    
    # --- Terraform Cloud ---
    if command -v terraform &>/dev/null; then
        echo ""
        echo "📦 Terraform"
        if [[ -f "$HOME/.terraform.d/credentials.tfrc.json" ]]; then
            echo "  ✅ Terraform Cloud credentials found"
        else
            read -p "  Configure Terraform Cloud login? [y/N]: " auth_terraform
            if [[ "$auth_terraform" =~ ^[Yy] ]]; then
                terraform login
            fi
        fi
    fi
    
    echo ""
    echo "✅ Cloud authentication setup complete!"
}

# Run authentication if not skipped via environment variable
if [[ "${SKIP_CLOUD_AUTH:-false}" != "true" ]]; then
    configure_cloud_auth
fi

