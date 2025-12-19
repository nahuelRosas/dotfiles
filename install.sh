#!/bin/bash
# ==============================================================================
# Dotfiles Install Script for Fedora
# ==============================================================================
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Paths
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
CONFIG_DIR="$HOME/.config"
ZSH_CONFIG_DIR="$CONFIG_DIR/zsh"

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

check_fedora() {
    if [[ ! -f /etc/fedora-release ]]; then
        print_error "Este script está diseñado para Fedora."
        print_warning "Sistema detectado: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
        exit 1
    fi
    print_success "Fedora detectado: $(cat /etc/fedora-release)"
}

create_backup() {
    print_header "📦 Creando Backup"
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
    
    print_success "Backup creado en: $BACKUP_DIR"
}

create_symlink() {
    local src="$1"
    local dest="$2"
    
    if [[ -e "$dest" ]] && [[ ! -L "$dest" ]]; then
        rm -rf "$dest"
    fi
    
    ln -sf "$src" "$dest"
    print_step "Symlink: $dest → $src"
}

# ==============================================================================
# Installation Functions
# ==============================================================================

install_base_packages() {
    print_header "📦 Instalando Paquetes Base"
    
    local packages=(
        "zsh"
        "git"
        "curl"
        "wget"
        "jq"
        "unzip"
        "util-linux-user"  # Para chsh
    )
    
    for pkg in "${packages[@]}"; do
        if ! rpm -q "$pkg" &>/dev/null; then
            print_step "Instalando $pkg..."
            sudo dnf install -y "$pkg"
        else
            print_success "$pkg ya instalado"
        fi
    done
}

setup_symlinks() {
    print_header "🔗 Configurando Symlinks"
    
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
    
    # P10k (si existe)
    if [[ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]]; then
        create_symlink "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
    fi
    
    print_success "Symlinks configurados"
}

run_setup_scripts() {
    print_header "⚙️ Ejecutando Scripts de Setup"
    
    local scripts=(
        "setup-fedora.sh"
        "setup-tools.sh"
        "setup-fonts.sh"
        "setup-docker.sh"
        "setup-nvm.sh"
        "setup-flatpak.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$DOTFILES_DIR/scripts/$script" ]]; then
            print_step "Ejecutando $script..."
            bash "$DOTFILES_DIR/scripts/$script"
        fi
    done
}

setup_oh_my_zsh() {
    print_header "🐚 Configurando Oh-My-Zsh"
    
    # Repair broken installation
    if [[ -d "$HOME/.oh-my-zsh" ]] && [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
        print_warning "Instalación rota de Oh-My-Zsh. Reparando..."
        rm -rf "$HOME/.oh-my-zsh"
    fi
    
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_step "Instalando Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        print_success "Oh-My-Zsh ya instalado"
    fi
}

setup_powerlevel10k() {
    print_header "🎨 Configurando Powerlevel10k"
    
    local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    
    if [[ ! -d "$p10k_dir" ]]; then
        print_step "Clonando Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    else
        print_step "Actualizando Powerlevel10k..."
        git -C "$p10k_dir" pull --quiet
    fi
    
    print_success "Powerlevel10k configurado"
}

setup_zsh_plugins() {
    print_header "🔌 Configurando Plugins Zsh"
    
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
        if [[ ! -d "$plugin_dir" ]]; then
            print_step "Instalando $plugin..."
            git clone --depth=1 "${plugins[$plugin]}" "$plugin_dir"
        else
            print_success "$plugin ya instalado"
        fi
    done
}

setup_fzf() {
    print_header "🔍 Configurando FZF"
    
    if [[ ! -d "$HOME/.fzf" ]]; then
        print_step "Instalando FZF..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        "$HOME/.fzf/install" --all --no-bash --no-fish
    else
        print_success "FZF ya instalado"
    fi
}

change_default_shell() {
    print_header "🐚 Cambiando Shell por Defecto"
    
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        print_step "Cambiando shell a zsh..."
        chsh -s "$(which zsh)"
        print_success "Shell cambiado a zsh (efectivo en próximo login)"
    else
        print_success "Zsh ya es el shell por defecto"
    fi
}

compile_zsh_files() {
    print_header "⚡ Compilando Archivos Zsh"
    
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
            print_step "Compilado: $file"
        fi
    done
    
    print_success "Archivos compilados para mayor velocidad"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    clear
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
    
    print_header "🚀 Iniciando Instalación"
    
    # Prerequisites
    check_fedora
    
    # Backup existing configs
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
    
    # Final message
    print_header "✅ Instalación Completa"
    echo -e "${GREEN}Tu terminal está lista!${NC}\n"
    echo -e "Próximos pasos:"
    echo -e "  ${CYAN}1.${NC} Reinicia la terminal o ejecuta: ${YELLOW}exec zsh${NC}"
    echo -e "  ${CYAN}2.${NC} Configura el prompt: ${YELLOW}p10k configure${NC}"
    echo -e "  ${CYAN}3.${NC} Configura Git:"
    echo -e "     ${YELLOW}git config --global user.name \"Tu Nombre\"${NC}"
    echo -e "     ${YELLOW}git config --global user.email \"tu@email.com\"${NC}"
    echo -e "\n${PURPLE}¡Disfruta tu nueva terminal!${NC} 🎉\n"
}

main "$@"
