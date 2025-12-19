#!/bin/bash
# ==============================================================================
# SSH Setup for GitHub/GitLab
# ==============================================================================
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_step() { echo -e "${BLUE}▶${NC} $1"; }
print_success() { echo -e "${GREEN}✔${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✖${NC} $1"; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 SSH Key Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ask if user wants to configure SSH
read -p "Do you want to configure SSH keys? [y/N]: " want_ssh
if [[ ! "$want_ssh" =~ ^[Yy] ]]; then
    echo ""
    print_warning "Skipping SSH configuration"
    echo ""
    exit 0
fi

SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Get email from git config
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [[ -z "$GIT_EMAIL" ]]; then
    read -p "Enter your email for SSH key: " GIT_EMAIL
    while [[ -z "$GIT_EMAIL" ]]; do
        echo -e "${RED}Email is required${NC}"
        read -p "Enter your email: " GIT_EMAIL
    done
fi

echo -e "${CYAN}Using email:${NC} $GIT_EMAIL"
echo ""


# Check for existing SSH keys
EXISTING_KEYS=$(ls -1 "$SSH_DIR"/*.pub 2>/dev/null || true)

if [[ -n "$EXISTING_KEYS" ]]; then
    echo -e "${GREEN}Found existing SSH keys:${NC}"
    echo ""
    for key in $EXISTING_KEYS; do
        key_name=$(basename "$key")
        key_comment=$(ssh-keygen -l -f "$key" 2>/dev/null | awk '{print $NF}' || echo "unknown")
        echo "  • $key_name ($key_comment)"
    done
    echo ""
    
    read -p "Create a new SSH key anyway? [y/N]: " create_new
    if [[ ! "$create_new" =~ ^[Yy] ]]; then
        echo ""
        read -p "Which key to use for GitHub? (filename without .pub): " selected_key
        selected_key=${selected_key:-id_ed25519}
        
        if [[ ! -f "$SSH_DIR/$selected_key" ]]; then
            print_error "Key not found: $SSH_DIR/$selected_key"
            exit 1
        fi
    else
        create_new="y"
    fi
else
    create_new="y"
fi

# Create new SSH key
if [[ "$create_new" =~ ^[Yy] ]]; then
    echo ""
    echo -e "${BOLD}SSH Key Type:${NC}"
    echo "  1) Ed25519 (recommended, modern)"
    echo "  2) RSA 4096 (legacy compatibility)"
    echo ""
    read -p "Select [1]: " key_type
    key_type=${key_type:-1}
    
    read -p "Key name [id_ed25519]: " key_name
    key_name=${key_name:-id_ed25519}
    
    KEY_PATH="$SSH_DIR/$key_name"
    
    echo ""
    print_step "Generating SSH key..."
    echo -e "${YELLOW}You can set a passphrase for extra security (or leave empty).${NC}"
    echo ""
    
    case $key_type in
        1)
            ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$KEY_PATH"
            ;;
        2)
            ssh-keygen -t rsa -b 4096 -C "$GIT_EMAIL" -f "$KEY_PATH"
            ;;
        *)
            ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$KEY_PATH"
            ;;
    esac
    
    selected_key="$key_name"
    print_success "SSH key created: $KEY_PATH"
fi

KEY_PATH="$SSH_DIR/$selected_key"
PUB_KEY_PATH="${KEY_PATH}.pub"

# Start ssh-agent and add key
echo ""
print_step "Adding key to ssh-agent..."

# Start ssh-agent if not running
if [[ -z "$SSH_AUTH_SOCK" ]]; then
    eval "$(ssh-agent -s)" > /dev/null
fi

# Add the key
ssh-add "$KEY_PATH" 2>/dev/null || {
    print_warning "Could not add key to ssh-agent (may need passphrase)"
}

# Configure SSH for GitHub
SSH_CONFIG="$SSH_DIR/config"
if ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    print_step "Configuring SSH for GitHub..."
    cat >> "$SSH_CONFIG" << EOF

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile $KEY_PATH
    AddKeysToAgent yes
EOF
    chmod 600 "$SSH_CONFIG"
    print_success "SSH config updated"
fi

# Add to GitHub
echo ""
echo -e "${BOLD}Add SSH key to GitHub${NC}"
echo ""

if command -v gh &>/dev/null; then
    if gh auth status &>/dev/null 2>&1; then
        read -p "Add SSH key to GitHub now? [Y/n]: " add_to_gh
        add_to_gh=${add_to_gh:-Y}
        
        if [[ "$add_to_gh" =~ ^[Yy] ]]; then
            # Check if key already exists
            PUB_KEY_CONTENT=$(cat "$PUB_KEY_PATH")
            existing=$(gh ssh-key list 2>/dev/null | grep -F "${PUB_KEY_CONTENT:0:50}" || true)
            
            if [[ -n "$existing" ]]; then
                print_success "SSH key already exists on GitHub"
            else
                read -p "Key title [$(hostname)]: " key_title
                key_title=${key_title:-$(hostname)}
                
                if gh ssh-key add "$PUB_KEY_PATH" --title "$key_title"; then
                    print_success "SSH key added to GitHub!"
                else
                    print_warning "Could not add key. Add manually:"
                    echo ""
                    echo "  1. Copy this key:"
                    echo ""
                    cat "$PUB_KEY_PATH"
                    echo ""
                    echo "  2. Go to: https://github.com/settings/ssh/new"
                fi
            fi
        fi
    else
        print_warning "GitHub CLI not authenticated"
        echo ""
        echo "To add your key manually:"
        echo "  1. Copy this key:"
        echo ""
        cat "$PUB_KEY_PATH"
        echo ""
        echo "  2. Go to: https://github.com/settings/ssh/new"
    fi
else
    echo "To add your key to GitHub:"
    echo "  1. Copy this key:"
    echo ""
    cat "$PUB_KEY_PATH"
    echo ""
    echo "  2. Go to: https://github.com/settings/ssh/new"
fi

# Test connection
echo ""
read -p "Test SSH connection to GitHub? [Y/n]: " test_conn
test_conn=${test_conn:-Y}

if [[ "$test_conn" =~ ^[Yy] ]]; then
    print_step "Testing GitHub connection..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        print_success "SSH connection to GitHub works!"
    else
        ssh -T git@github.com 2>&1 || true
    fi
fi

echo ""
print_success "SSH setup complete!"
echo ""
echo -e "${CYAN}To clone repos via SSH:${NC}"
echo "  git clone git@github.com:username/repo.git"
