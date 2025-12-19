#!/bin/bash
# ==============================================================================
# Dotfiles Install Script for Fedora
# Enhanced with interactive options, backup management, and install modes
# ==============================================================================
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Paths
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
CONFIG_DIR="$HOME/.config"
ZSH_CONFIG_DIR="$CONFIG_DIR/zsh"

# Installation options (defaults)
CREATE_BACKUP=true
FORCE_REINSTALL=false
INSTALL_NVIDIA=false
INSTALL_VPN=false
INSTALL_CLOUD=false

# ==============================================================================
# Helper Functions
# ==============================================================================

print_header() {
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_step() {
    echo -e "${BLUE}▶${NC} $1"
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

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
    ____        __  _____ __         
   / __ \____  / /_/ __(_) /__  _____
  / / / / __ \/ __/ /_/ / / _ \/ ___/
 / /_/ / /_/ / /_/ __/ / /  __(__  ) 
/_____/\____/\__/_/ /_/_/\___/____/  
                                     
    Fedora Terminal Setup Script
EOF
    echo -e "${NC}"
}

# ==============================================================================
# Pre-flight Checks
# ==============================================================================

# Distro detection variables
DISTRO=""
PKG_MANAGER=""
PKG_INSTALL=""
PKG_UPDATE=""

detect_distro() {
    if [[ -f /etc/fedora-release ]]; then
        DISTRO="fedora"
        PKG_MANAGER="dnf"
        PKG_INSTALL="sudo dnf install -y"
        PKG_UPDATE="sudo dnf upgrade -y"
        print_success "Fedora detected: $(cat /etc/fedora-release)"
    elif [[ -f /etc/debian_version ]]; then
        if [[ -f /etc/lsb-release ]] && grep -q "Ubuntu" /etc/lsb-release; then
            DISTRO="ubuntu"
        else
            DISTRO="debian"
        fi
        PKG_MANAGER="apt"
        PKG_INSTALL="sudo apt install -y"
        PKG_UPDATE="sudo apt update && sudo apt upgrade -y"
        print_success "$DISTRO detected: $(cat /etc/debian_version)"
    elif [[ -f /etc/arch-release ]]; then
        DISTRO="arch"
        PKG_MANAGER="pacman"
        PKG_INSTALL="sudo pacman -S --noconfirm"
        PKG_UPDATE="sudo pacman -Syu --noconfirm"
        print_success "Arch Linux detected"
    elif [[ "$(uname)" == "Darwin" ]]; then
        DISTRO="macos"
        PKG_MANAGER="brew"
        PKG_INSTALL="brew install"
        PKG_UPDATE="brew update && brew upgrade"
        print_success "macOS detected: $(sw_vers -productVersion)"
        
        # Check for Homebrew
        if ! command -v brew &>/dev/null; then
            print_warning "Homebrew not found. Installing..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
    else
        print_error "Unsupported operating system"
        print_warning "Detected: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 || uname -s)"
        print_warning "Supported: Fedora, Ubuntu/Debian, Arch Linux, macOS"
        exit 1
    fi
    
    export DISTRO PKG_MANAGER PKG_INSTALL PKG_UPDATE
}

# Legacy function for backward compatibility
check_fedora() {
    detect_distro
}


request_sudo() {
    print_header "🔐 Requesting Administrator Privileges"
    echo -e "${YELLOW}This script requires sudo access to install packages.${NC}"
    echo -e "Please enter your password to continue:\n"
    
    # Request sudo and keep it alive
    if sudo -v; then
        print_success "Administrator privileges granted"
        # Keep sudo alive in background
        (while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null) &
    else
        print_error "Failed to obtain administrator privileges"
        exit 1
    fi
}

# ==============================================================================
# Interactive Menu Functions
# ==============================================================================

show_backup_menu() {
    print_header "📦 Backup Options"
    
    # Count existing backups
    local backup_count=$(ls -d ~/.dotfiles-backup-* 2>/dev/null | wc -l)
    
    if [[ $backup_count -gt 0 ]]; then
        echo -e "Found ${YELLOW}$backup_count${NC} existing backup(s):\n"
        ls -dt ~/.dotfiles-backup-* 2>/dev/null | head -5 | while read dir; do
            echo "  • $(basename $dir)"
        done
        [[ $backup_count -gt 5 ]] && echo "  ... and $((backup_count - 5)) more"
        echo ""
    fi
    
    echo -e "${BOLD}What would you like to do?${NC}\n"
    echo "  1) Create new backup (recommended)"
    echo "  2) Skip backup"
    echo "  3) Clean old backups (keep only latest)"
    echo "  4) Delete ALL backups"
    echo ""
    
    read -p "Select option [1]: " backup_choice
    backup_choice=${backup_choice:-1}
    
    case $backup_choice in
        1)
            CREATE_BACKUP=true
            ;;
        2)
            CREATE_BACKUP=false
            print_warning "Skipping backup creation"
            ;;
        3)
            clean_old_backups
            CREATE_BACKUP=true
            ;;
        4)
            delete_all_backups
            CREATE_BACKUP=true
            ;;
        *)
            CREATE_BACKUP=true
            ;;
    esac
}

show_install_menu() {
    print_header "🔧 Installation Mode"
    
    echo -e "${BOLD}Select installation mode:${NC}\n"
    echo "  1) Fresh install (skip already installed packages)"
    echo "  2) Reinstall (force reinstall all packages)"
    echo ""
    
    read -p "Select option [1]: " install_choice
    install_choice=${install_choice:-1}
    
    case $install_choice in
        1)
            FORCE_REINSTALL=false
            print_success "Fresh install mode selected"
            ;;
        2)
            FORCE_REINSTALL=true
            print_warning "Reinstall mode: all packages will be reinstalled"
            ;;
        *)
            FORCE_REINSTALL=false
            ;;
    esac
}

show_extras_menu() {
    print_header "➕ Additional Components"
    
    echo -e "${BOLD}Optional components to install:${NC}\n"
    
    # Check for NVIDIA GPU
    if lspci 2>/dev/null | grep -qi nvidia; then
        echo -e "  ${GREEN}✓${NC} NVIDIA GPU detected!"
        read -p "Install NVIDIA proprietary drivers? [Y/n]: " nvidia_choice
        nvidia_choice=${nvidia_choice:-Y}
        [[ "$nvidia_choice" =~ ^[Yy] ]] && INSTALL_NVIDIA=true
    fi
    
    # VPN option (default: Yes)
    read -p "Install VPN tools (OpenVPN + WireGuard)? [Y/n]: " vpn_choice
    vpn_choice=${vpn_choice:-Y}
    [[ "$vpn_choice" =~ ^[Yy] ]] && INSTALL_VPN=true
    
    # Cloud CLI option (default: Yes)
    read -p "Install Cloud CLIs (AWS, GCloud, Firebase, Terraform, kubectl)? [Y/n]: " cloud_choice
    cloud_choice=${cloud_choice:-Y}
    [[ "$cloud_choice" =~ ^[Yy] ]] && INSTALL_CLOUD=true
}

# ==============================================================================
# Backup Functions
# ==============================================================================

create_backup() {
    if [[ "$CREATE_BACKUP" != true ]]; then
        return
    fi
    
    print_header "📦 Creating Backup"
    mkdir -p "$BACKUP_DIR"
    
    local files_to_backup=(
        "$HOME/.zshrc"
        "$HOME/.zshenv"
        "$HOME/.zprofile"
        "$HOME/.zlogout"
        "$HOME/.p10k.zsh"
        "$CONFIG_DIR/kitty"
        "$HOME/.gitconfig"
    )
    
    for file in "${files_to_backup[@]}"; do
        if [[ -e "$file" ]]; then
            cp -r "$file" "$BACKUP_DIR/" 2>/dev/null || true
            print_step "Backup: $file"
        fi
    done
    
    print_success "Backup created at: $BACKUP_DIR"
}

clean_old_backups() {
    print_step "Cleaning old backups (keeping latest)..."
    local backups=($(ls -dt ~/.dotfiles-backup-* 2>/dev/null))
    local count=${#backups[@]}
    
    if [[ $count -le 1 ]]; then
        print_success "No old backups to clean"
        return
    fi
    
    # Remove all except the latest
    for ((i=1; i<count; i++)); do
        rm -rf "${backups[$i]}"
        print_step "Removed: $(basename ${backups[$i]})"
    done
    
    print_success "Cleaned $((count - 1)) old backup(s)"
}

delete_all_backups() {
    print_warning "This will delete ALL backup directories!"
    read -p "Are you sure? [y/N]: " confirm
    
    if [[ "$confirm" =~ ^[Yy] ]]; then
        rm -rf ~/.dotfiles-backup-* 2>/dev/null
        print_success "All backups deleted"
    else
        print_step "Cancelled"
    fi
}

# ==============================================================================
# Symlink Functions
# ==============================================================================

create_symlink() {
    local src="$1"
    local dest="$2"
    
    if [[ -e "$dest" ]] && [[ ! -L "$dest" ]]; then
        rm -rf "$dest"
    fi
    
    ln -sf "$src" "$dest"
    print_step "Symlink: $dest → $src"
}

setup_symlinks() {
    print_header "🔗 Configuring Symlinks"
    
    # Zsh files
    create_symlink "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    create_symlink "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"
    create_symlink "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
    create_symlink "$DOTFILES_DIR/zsh/.zlogout" "$HOME/.zlogout"
    
    # Zsh config directory
    mkdir -p "$ZSH_CONFIG_DIR"
    create_symlink "$DOTFILES_DIR/zsh/aliases.zsh" "$ZSH_CONFIG_DIR/aliases.zsh"
    create_symlink "$DOTFILES_DIR/zsh/functions.zsh" "$ZSH_CONFIG_DIR/functions.zsh"
    create_symlink "$DOTFILES_DIR/zsh/lazy-loaders.zsh" "$ZSH_CONFIG_DIR/lazy-loaders.zsh"
    create_symlink "$DOTFILES_DIR/zsh/completions.zsh" "$ZSH_CONFIG_DIR/completions.zsh"
    
    # Kitty
    mkdir -p "$CONFIG_DIR/kitty"
    create_symlink "$DOTFILES_DIR/kitty/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf"
    create_symlink "$DOTFILES_DIR/kitty/dracula.conf" "$CONFIG_DIR/kitty/dracula.conf"
    
    # Git
    if [[ -f "$DOTFILES_DIR/git/.gitconfig" ]]; then
        create_symlink "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
    fi
    
    # P10k (if exists)
    if [[ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]]; then
        create_symlink "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
    fi
    
    print_success "Symlinks configured"
}

# ==============================================================================
# Installation Functions
# ==============================================================================

install_base_packages() {
    print_header "📦 Installing Base Packages"
    
    local packages=(
        "zsh"
        "git"
        "curl"
        "wget"
        "jq"
        "unzip"
        "util-linux-user"  # For chsh
    )
    
    local install_cmd="sudo dnf install -y --skip-unavailable"
    [[ "$FORCE_REINSTALL" == true ]] && install_cmd="sudo dnf reinstall -y --skip-unavailable"
    
    for pkg in "${packages[@]}"; do
        if [[ "$FORCE_REINSTALL" == true ]] || ! rpm -q "$pkg" &>/dev/null; then
            print_step "Installing $pkg..."
            $install_cmd "$pkg" 2>/dev/null || true
        else
            print_success "$pkg already installed"
        fi
    done
}

run_setup_scripts() {
    print_header "⚙️ Running Setup Scripts"
    
    local scripts=(
        "setup-fedora.sh"
        "setup-tools.sh"
        "setup-fonts.sh"
        "setup-docker.sh"
        "setup-nvm.sh"
        "setup-flatpak.sh"
    )
    
    [[ "$INSTALL_NVIDIA" == true ]] && scripts+=("setup-nvidia.sh")
    [[ "$INSTALL_VPN" == true ]] && scripts+=("setup-vpn.sh")
    [[ "$INSTALL_CLOUD" == true ]] && scripts+=("setup-cloud.sh")
    
    for script in "${scripts[@]}"; do
        if [[ -f "$DOTFILES_DIR/scripts/$script" ]]; then
            print_step "Running $script..."
            # Pass FORCE_REINSTALL to subscripts
            FORCE_REINSTALL="$FORCE_REINSTALL" bash "$DOTFILES_DIR/scripts/$script"
        fi
    done
}

setup_oh_my_zsh() {
    print_header "🐚 Configuring Oh-My-Zsh"
    
    # Repair broken installation
    if [[ -d "$HOME/.oh-my-zsh" ]] && [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
        print_warning "Broken Oh-My-Zsh installation. Repairing..."
        rm -rf "$HOME/.oh-my-zsh"
    fi
    
    if [[ "$FORCE_REINSTALL" == true ]] && [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_step "Reinstalling Oh-My-Zsh..."
        rm -rf "$HOME/.oh-my-zsh"
    fi
    
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_step "Installing Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        print_success "Oh-My-Zsh already installed"
    fi
}

setup_powerlevel10k() {
    print_header "🎨 Configuring Powerlevel10k"
    
    local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    
    if [[ "$FORCE_REINSTALL" == true ]] && [[ -d "$p10k_dir" ]]; then
        rm -rf "$p10k_dir"
    fi
    
    if [[ ! -d "$p10k_dir" ]]; then
        print_step "Cloning Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    else
        print_step "Updating Powerlevel10k..."
        git -C "$p10k_dir" pull --quiet
    fi
    
    print_success "Powerlevel10k configured"
}

setup_zsh_plugins() {
    print_header "🔌 Configuring Zsh Plugins"
    
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    declare -A plugins=(
        ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
        ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
        ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search.git"
        ["zsh-completions"]="https://github.com/zsh-users/zsh-completions.git"
        ["zsh-z"]="https://github.com/agkozak/zsh-z.git"
        ["zsh-vi-mode"]="https://github.com/jeffreytse/zsh-vi-mode.git"
    )
    
    for plugin in "${!plugins[@]}"; do
        local plugin_dir="$ZSH_CUSTOM/plugins/$plugin"
        
        if [[ "$FORCE_REINSTALL" == true ]] && [[ -d "$plugin_dir" ]]; then
            rm -rf "$plugin_dir"
        fi
        
        if [[ ! -d "$plugin_dir" ]]; then
            print_step "Installing $plugin..."
            git clone --depth=1 "${plugins[$plugin]}" "$plugin_dir"
        else
            print_success "$plugin already installed"
        fi
    done
}

setup_fzf() {
    print_header "🔍 Configuring FZF"
    
    if [[ "$FORCE_REINSTALL" == true ]] && [[ -d "$HOME/.fzf" ]]; then
        rm -rf "$HOME/.fzf"
    fi
    
    if [[ ! -d "$HOME/.fzf" ]]; then
        print_step "Installing FZF..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        "$HOME/.fzf/install" --all --no-bash --no-fish
    else
        print_success "FZF already installed"
    fi
}

change_default_shell() {
    print_header "🐚 Changing Default Shell"
    
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        print_step "Changing shell to zsh..."
        chsh -s "$(which zsh)"
        print_success "Shell changed to zsh (effective on next login)"
    else
        print_success "Zsh is already the default shell"
    fi
}

compile_zsh_files() {
    print_header "⚡ Compiling Zsh Files"
    
    local files=(
        "$HOME/.zshrc"
        "$HOME/.zshenv"
        "$HOME/.zprofile"
        "$ZSH_CONFIG_DIR/aliases.zsh"
        "$ZSH_CONFIG_DIR/functions.zsh"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            zsh -c "zcompile '$file'" 2>/dev/null || true
            print_step "Compiled: $file"
        fi
    done
    
    print_success "Files compiled for faster loading"
}

# ==============================================================================
# Post-Installation Configuration
# ==============================================================================

configure_git() {
    print_header "🔧 Git Configuration"
    
    local current_name=$(git config --global user.name 2>/dev/null || echo "")
    local current_email=$(git config --global user.email 2>/dev/null || echo "")
    
    echo -e "${BOLD}Configure your Git identity:${NC}\n"
    
    # Get user name
    if [[ -n "$current_name" ]]; then
        read -p "Your name [$current_name]: " git_name
        git_name=${git_name:-$current_name}
    else
        read -p "Your name: " git_name
        while [[ -z "$git_name" ]]; do
            echo -e "${RED}Name is required${NC}"
            read -p "Your name: " git_name
        done
    fi
    
    # Get user email
    if [[ -n "$current_email" ]]; then
        read -p "Your email [$current_email]: " git_email
        git_email=${git_email:-$current_email}
    else
        read -p "Your email: " git_email
        while [[ -z "$git_email" ]]; do
            echo -e "${RED}Email is required${NC}"
            read -p "Your email: " git_email
        done
    fi
    
    # Set Git config
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    print_success "Git configured for: $git_name <$git_email>"
    
    # Check if email matches any existing GPG key
    if command -v gpg &>/dev/null; then
        local gpg_emails=$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep -oP '(?<=<)[^>]+(?=>)' | sort -u)
        
        if [[ -n "$gpg_emails" ]]; then
            if ! echo "$gpg_emails" | grep -q "^${git_email}$"; then
                echo ""
                echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${YELLOW}⚠ WARNING: Git email does not match any GPG key${NC}"
                echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo ""
                echo -e "Git email: ${CYAN}$git_email${NC}"
                echo -e "GPG key email(s):"
                echo "$gpg_emails" | while read email; do
                    echo -e "  • ${GREEN}$email${NC}"
                done
                echo ""
                echo -e "${BOLD}Your commits won't show as 'Verified' on GitHub unless emails match.${NC}"
                echo ""
                echo "Options:"
                echo "  1) Create a NEW GPG key for $git_email"
                echo "  2) Change Git email to match existing GPG key"
                echo "  3) Continue anyway (commits won't be verified)"
                echo ""
                
                read -p "Select option [1]: " gpg_mismatch_choice
                gpg_mismatch_choice=${gpg_mismatch_choice:-1}
                
                case $gpg_mismatch_choice in
                    1)
                        echo ""
                        print_step "A new GPG key will be created during GPG configuration..."
                        ;;
                    2)
                        local first_gpg_email=$(echo "$gpg_emails" | head -1)
                        echo ""
                        echo "Available GPG emails:"
                        local i=1
                        echo "$gpg_emails" | while read email; do
                            echo "  $i) $email"
                            ((i++))
                        done
                        echo ""
                        read -p "Select email number [1]: " email_choice
                        email_choice=${email_choice:-1}
                        local selected_email=$(echo "$gpg_emails" | sed -n "${email_choice}p")
                        selected_email=${selected_email:-$first_gpg_email}
                        
                        git config --global user.email "$selected_email"
                        git_email="$selected_email"
                        print_success "Git email changed to: $selected_email"
                        ;;
                    3)
                        print_warning "Continuing without GPG email match. Commits won't be verified."
                        ;;
                esac
            fi
        fi
    fi
}

configure_gpg() {
    print_header "🔐 GPG Configuration for Commit Signing"
    
    # Check if gpg is installed
    if ! command -v gpg &>/dev/null; then
        print_warning "GPG not installed. Installing..."
        sudo dnf install -y gnupg2
    fi
    
    # Get current Git identity
    local git_name=$(git config --global user.name 2>/dev/null || echo "")
    local git_email=$(git config --global user.email 2>/dev/null || echo "")
    
    if [[ -z "$git_email" ]]; then
        print_error "Git email not configured. Please run 'git config --global user.email' first."
        return 1
    fi
    
    echo -e "${CYAN}Git identity:${NC} $git_name <$git_email>\n"
    
    # Check for existing GPG keys
    local gpg_output=$(gpg --list-secret-keys --keyid-format=long 2>/dev/null)
    local gpg_keys=$(echo "$gpg_output" | grep -E "^sec" | awk '{print $2}' | cut -d'/' -f2)
    
    local selected_key=""
    local need_new_key=false
    
    if [[ -z "$gpg_keys" ]]; then
        echo -e "${YELLOW}No GPG keys found.${NC}\n"
        need_new_key=true
    else
        # Show existing keys with their emails
        echo -e "${GREEN}Found existing GPG key(s):${NC}\n"
        
        local key_info=""
        local match_found=false
        
        while IFS= read -r key_id; do
            [[ -z "$key_id" ]] && continue
            
            local key_email=$(gpg --list-secret-keys --keyid-format=long "$key_id" 2>/dev/null | grep -oP '(?<=<)[^>]+(?=>)' | head -1)
            local key_name=$(gpg --list-secret-keys --keyid-format=long "$key_id" 2>/dev/null | grep "^uid" | sed 's/uid.*\] //' | sed 's/ <.*//' | head -1)
            
            echo -e "  ${BOLD}Key:${NC} $key_id"
            echo -e "  ${BOLD}Name:${NC} $key_name"
            echo -e "  ${BOLD}Email:${NC} $key_email"
            
            if [[ "$key_email" == "$git_email" ]]; then
                echo -e "  ${GREEN}✓ Matches Git email${NC}"
                match_found=true
                selected_key="$key_id"
            else
                echo -e "  ${YELLOW}⚠ Does NOT match Git email ($git_email)${NC}"
            fi
            echo ""
        done <<< "$gpg_keys"
        
        if [[ "$match_found" == false ]]; then
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}⚠ WARNING: No GPG key matches your Git email ($git_email)${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo -e "${BOLD}Options:${NC}"
            echo "  1) Create a NEW GPG key with your Git email (recommended)"
            echo "  2) Use existing key anyway (commits may not be verified on GitHub)"
            echo "  3) Change Git email to match existing GPG key"
            echo "  4) Skip GPG configuration"
            echo ""
            
            read -p "Select option [1]: " mismatch_choice
            mismatch_choice=${mismatch_choice:-1}
            
            case $mismatch_choice in
                1)
                    need_new_key=true
                    ;;
                2)
                    # Let user select from existing keys
                    local key_count=$(echo "$gpg_keys" | wc -l)
                    if [[ $key_count -gt 1 ]]; then
                        echo ""
                        echo -e "${BOLD}Select key to use:${NC}"
                        local i=1
                        while IFS= read -r key_id; do
                            [[ -z "$key_id" ]] && continue
                            local key_email=$(gpg --list-secret-keys --keyid-format=long "$key_id" 2>/dev/null | grep -oP '(?<=<)[^>]+(?=>)' | head -1)
                            echo "  $i) $key_id ($key_email)"
                            ((i++))
                        done <<< "$gpg_keys"
                        echo ""
                        read -p "Select key [1]: " key_choice
                        key_choice=${key_choice:-1}
                        selected_key=$(echo "$gpg_keys" | sed -n "${key_choice}p")
                    else
                        selected_key=$(echo "$gpg_keys" | head -1)
                    fi
                    ;;
                3)
                    # Change Git email to match GPG
                    local first_key=$(echo "$gpg_keys" | head -1)
                    local gpg_email=$(gpg --list-secret-keys --keyid-format=long "$first_key" 2>/dev/null | grep -oP '(?<=<)[^>]+(?=>)' | head -1)
                    local gpg_name=$(gpg --list-secret-keys --keyid-format=long "$first_key" 2>/dev/null | grep "^uid" | sed 's/uid.*\] //' | sed 's/ <.*//' | head -1)
                    
                    echo ""
                    echo -e "This will change your Git identity to:"
                    echo -e "  Name:  ${CYAN}$gpg_name${NC}"
                    echo -e "  Email: ${CYAN}$gpg_email${NC}"
                    echo ""
                    read -p "Proceed? [Y/n]: " confirm_change
                    confirm_change=${confirm_change:-Y}
                    
                    if [[ "$confirm_change" =~ ^[Yy] ]]; then
                        git config --global user.name "$gpg_name"
                        git config --global user.email "$gpg_email"
                        git_name="$gpg_name"
                        git_email="$gpg_email"
                        selected_key="$first_key"
                        print_success "Git identity updated to: $gpg_name <$gpg_email>"
                    else
                        print_warning "Cancelled. Skipping GPG configuration."
                        return 0
                    fi
                    ;;
                4)
                    print_warning "Skipping GPG configuration"
                    return 0
                    ;;
                *)
                    need_new_key=true
                    ;;
            esac
        fi
    fi
    
    # Create new key if needed
    if [[ "$need_new_key" == true ]]; then
        echo ""
        read -p "Create a new GPG key for $git_name <$git_email>? [Y/n]: " create_key
        create_key=${create_key:-Y}
        
        if [[ "$create_key" =~ ^[Yy] ]]; then
            print_step "Creating GPG key for: $git_name <$git_email>"
            echo ""
            echo -e "${CYAN}You will be prompted to set a passphrase for your GPG key.${NC}"
            echo -e "${YELLOW}Remember this passphrase - you'll need it to sign commits.${NC}"
            echo ""
            
            # Generate GPG key
            gpg --batch --gen-key <<EOF
Key-Type: eddsa
Key-Curve: ed25519
Key-Usage: sign
Subkey-Type: ecdh
Subkey-Curve: cv25519
Subkey-Usage: encrypt
Name-Real: $git_name
Name-Email: $git_email
Expire-Date: 0
%commit
EOF
            
            # Get the new key ID
            selected_key=$(gpg --list-secret-keys --keyid-format=long "$git_email" 2>/dev/null | grep -E "^sec" | awk '{print $2}' | cut -d'/' -f2 | head -1)
            
            if [[ -n "$selected_key" ]]; then
                print_success "GPG key created: $selected_key"
            else
                print_error "Failed to create GPG key"
                return 1
            fi
        else
            print_warning "Skipping GPG configuration"
            return 0
        fi
    fi
    
    # Validate we have a key
    if [[ -z "$selected_key" ]]; then
        print_error "No GPG key selected"
        return 1
    fi
    
    echo ""
    print_step "Configuring Git to use GPG key: $selected_key"
    
    # Configure Git for GPG signing
    git config --global user.signingkey "$selected_key"
    git config --global commit.gpgsign true
    git config --global tag.gpgsign true
    git config --global gpg.program gpg
    
    print_success "Git configured for GPG signing"
    
    # === GitHub Integration ===
    if command -v gh &>/dev/null; then
        echo ""
        echo -e "${BOLD}GitHub Integration${NC}"
        echo ""
        
        # Check if authenticated with gh
        if ! gh auth status &>/dev/null; then
            print_warning "GitHub CLI not authenticated"
            read -p "Authenticate with GitHub now? [Y/n]: " auth_gh
            auth_gh=${auth_gh:-Y}
            
            if [[ "$auth_gh" =~ ^[Yy] ]]; then
                print_step "Starting GitHub authentication..."
                gh auth login
            else
                print_warning "Skipping GitHub integration"
                echo "  To add your GPG key later:"
                echo "    gpg --armor --export $selected_key | gh gpg-key add -"
                echo ""
                print_success "GPG configuration complete!"
                return 0
            fi
        fi
        
        # Check if key already exists on GitHub BEFORE asking
        local existing_keys=""
        if gh gpg-key list &>/dev/null 2>&1; then
            existing_keys=$(gh gpg-key list 2>/dev/null | grep -i "$selected_key" || true)
        fi
        
        if [[ -n "$existing_keys" ]]; then
            print_success "GPG key already exists on GitHub!"
        else
            read -p "Add GPG public key to GitHub? [Y/n]: " add_to_gh
            add_to_gh=${add_to_gh:-Y}
            
            if [[ "$add_to_gh" =~ ^[Yy] ]]; then
                # Check if we have required scopes
                if ! gh gpg-key list &>/dev/null 2>&1; then
                    print_step "Requesting GitHub GPG permissions..."
                    echo -e "${YELLOW}This will open your browser to authorize GPG key access.${NC}"
                    echo ""
                    gh auth refresh -s admin:gpg_key
                    
                    if [[ $? -ne 0 ]]; then
                        print_warning "Could not get GPG permissions. You can add the key manually:"
                        echo "  gpg --armor --export $selected_key | gh gpg-key add -"
                        return 0
                    fi
                fi
                
                print_step "Adding GPG key to GitHub..."
                
                if gpg --armor --export "$selected_key" | gh gpg-key add - 2>/dev/null; then
                    print_success "GPG key added to GitHub!"
                    echo ""
                    echo -e "${GREEN}Your commits will now show as 'Verified' on GitHub!${NC}"
                else
                    print_warning "Could not add key to GitHub automatically."
                    echo ""
                    echo "  Manual steps:"
                    echo "    1. Run: gpg --armor --export $selected_key"
                    echo "    2. Copy the output (including BEGIN/END lines)"
                    echo "    3. Go to: https://github.com/settings/gpg/new"
                    echo "    4. Paste and save"
                fi
            fi
        fi
    else
        echo ""
        print_warning "GitHub CLI (gh) not installed."
        echo "  To add your GPG key to GitHub manually:"
        echo "    1. Run: gpg --armor --export $selected_key"
        echo "    2. Copy the output"
        echo "    3. Go to: https://github.com/settings/gpg/new"
    fi
    
    echo ""
    print_success "GPG configuration complete!"
    echo ""
    echo -e "${CYAN}Test signing with:${NC} echo 'test' | gpg --clearsign"
    echo -e "${CYAN}Test commit with:${NC} git commit --allow-empty -m 'test: gpg signing'"
}

configure_ssh() {
    print_header "🔑 SSH Key Configuration"
    
    # Check if SSH key already exists
    if ls ~/.ssh/*.pub &>/dev/null; then
        echo -e "${GREEN}Found existing SSH keys:${NC}"
        for key in ~/.ssh/*.pub; do
            echo "  • $(basename $key)"
        done
        echo ""
        read -p "Configure SSH anyway? [y/N]: " setup_ssh
        if [[ ! "$setup_ssh" =~ ^[Yy] ]]; then
            print_step "Skipping SSH configuration"
            return 0
        fi
    fi
    
    # Run the dedicated SSH setup script
    if [[ -f "$DOTFILES_DIR/scripts/setup-ssh.sh" ]]; then
        bash "$DOTFILES_DIR/scripts/setup-ssh.sh"
    else
        print_warning "SSH setup script not found"
        echo ""
        echo "To generate an SSH key manually:"
        echo "  ssh-keygen -t ed25519 -C \"your_email@example.com\""
        echo ""
        echo "To add to GitHub:"
        echo "  gh ssh-key add ~/.ssh/id_ed25519.pub"
    fi
}

configure_p10k() {
    print_header "🎨 Powerlevel10k Configuration"
    
    # Check if terminal is interactive and large enough for p10k wizard
    local cols=$(tput cols 2>/dev/null || echo 0)
    local lines=$(tput lines 2>/dev/null || echo 0)
    
    if [[ ! -t 0 ]] || [[ "$cols" -lt 47 ]] || [[ "$lines" -lt 14 ]]; then
        print_warning "Terminal is too small or non-interactive for p10k wizard"
        echo "  Current size: ${cols}x${lines} (minimum required: 47x14)"
        echo ""
        echo "  To configure Powerlevel10k later:"
        echo "    1. Open a full-screen terminal"
        echo "    2. Run: ${CYAN}p10k configure${NC}"
        echo ""
        return 0
    fi
    
    echo -e "${BOLD}Would you like to configure Powerlevel10k now?${NC}\n"
    echo "This will start the interactive configuration wizard."
    echo ""
    
    read -p "Configure Powerlevel10k? [Y/n]: " p10k_choice
    p10k_choice=${p10k_choice:-Y}
    
    if [[ "$p10k_choice" =~ ^[Yy] ]]; then
        print_step "Starting Powerlevel10k configuration wizard..."
        echo ""
        echo -e "${YELLOW}Note: After completing the wizard, run 'exec zsh' to reload.${NC}"
        echo ""
        # Run p10k configure in a new zsh shell
        zsh -c "source ~/.zshrc 2>/dev/null; p10k configure" || {
            print_warning "Could not start p10k wizard. Run 'p10k configure' after restarting your terminal."
        }
    else
        echo ""
        print_step "Skipping p10k configuration. Run 'p10k configure' later to customize your prompt."
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    clear
    print_banner
    
    print_header "🚀 Starting Installation"
    
    # Prerequisites
    check_fedora
    
    # Request sudo upfront
    request_sudo
    
    # Interactive menus
    show_backup_menu
    show_install_menu
    show_extras_menu
    
    # Create backup if selected
    create_backup
    
    # Install base packages
    install_base_packages
    
    # Setup Oh-My-Zsh and related
    setup_oh_my_zsh
    setup_powerlevel10k
    setup_zsh_plugins
    setup_fzf
    
    # Create symlinks
    setup_symlinks
    
    # Run additional setup scripts
    run_setup_scripts
    
    # Change shell
    change_default_shell
    
    # Compile for performance
    compile_zsh_files
    
    # Post-installation configuration
    configure_git
    configure_gpg
    configure_ssh
    configure_p10k
    
    # Final message
    print_header "✅ Installation Complete"
    echo -e "${GREEN}Your terminal is ready!${NC}\n"
    echo -e "Installed components:"
    echo -e "  ${CYAN}•${NC} Oh-My-Zsh with Powerlevel10k"
    echo -e "  ${CYAN}•${NC} Zsh plugins (syntax highlighting, autosuggestions, etc.)"
    echo -e "  ${CYAN}•${NC} FZF fuzzy finder"
    echo -e "  ${CYAN}•${NC} Modern CLI tools (bat, lsd, fd, ripgrep, etc.)"
    [[ "$INSTALL_NVIDIA" == true ]] && echo -e "  ${CYAN}•${NC} NVIDIA drivers ${YELLOW}(reboot required)${NC}"
    [[ "$INSTALL_VPN" == true ]] && echo -e "  ${CYAN}•${NC} VPN tools (OpenVPN, WireGuard)"
    [[ "$INSTALL_CLOUD" == true ]] && echo -e "  ${CYAN}•${NC} Cloud CLIs (AWS, GCloud, Firebase, Terraform, etc.)"
    echo ""
    echo -e "${YELLOW}Next step:${NC} Restart your terminal or run: ${CYAN}exec zsh${NC}"
    echo -e "\n${PURPLE}Enjoy your new terminal!${NC} 🎉\n"
}

main "$@"
