#!/bin/bash
# ==============================================================================
# Uninstall Script - Revert dotfiles installation
# ==============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
    ____        __  _____ __         
   / __ \____  / /_/ __(_) /__  _____
  / / / / __ \/ __/ /_/ / / _ \/ ___/
 / /_/ / /_/ / /_/ __/ / /  __(__  ) 
/_____/\____/\__/_/ /_/_/\___/____/  
                                     
    Uninstall Script
EOF
echo -e "${NC}"

echo -e "${YELLOW}⚠️  This will remove dotfiles symlinks${NC}"
echo ""

# Find latest backup
LATEST_BACKUP=$(ls -td ~/.dotfiles-backup-* 2>/dev/null | head -1)

if [[ -n "$LATEST_BACKUP" ]]; then
    echo -e "Found backup: ${GREEN}$LATEST_BACKUP${NC}"
    echo ""
fi

read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo -e "${CYAN}Removing symlinks...${NC}"

# Zsh files
rm -f ~/.zshrc
rm -f ~/.zshenv
rm -f ~/.zprofile
rm -f ~/.zlogout
rm -f ~/.p10k.zsh

# Zsh config directory
rm -f ~/.config/zsh/aliases.zsh
rm -f ~/.config/zsh/functions.zsh
rm -f ~/.config/zsh/lazy-loaders.zsh
rm -f ~/.config/zsh/completions.zsh

# Kitty
rm -f ~/.config/kitty/kitty.conf
rm -f ~/.config/kitty/dracula.conf

# Git
rm -f ~/.gitconfig

echo -e "${GREEN}✔${NC} Symlinks removed"

# Restore backup if available
if [[ -n "$LATEST_BACKUP" ]]; then
    echo ""
    read -p "Restore backup from $LATEST_BACKUP? (y/N) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Restoring backup...${NC}"
        
        [[ -f "$LATEST_BACKUP/.zshrc" ]] && cp "$LATEST_BACKUP/.zshrc" ~/
        [[ -f "$LATEST_BACKUP/.zshenv" ]] && cp "$LATEST_BACKUP/.zshenv" ~/
        [[ -f "$LATEST_BACKUP/.zprofile" ]] && cp "$LATEST_BACKUP/.zprofile" ~/
        [[ -f "$LATEST_BACKUP/.zlogout" ]] && cp "$LATEST_BACKUP/.zlogout" ~/
        [[ -f "$LATEST_BACKUP/.p10k.zsh" ]] && cp "$LATEST_BACKUP/.p10k.zsh" ~/
        [[ -f "$LATEST_BACKUP/.gitconfig" ]] && cp "$LATEST_BACKUP/.gitconfig" ~/
        [[ -d "$LATEST_BACKUP/kitty" ]] && cp -r "$LATEST_BACKUP/kitty" ~/.config/
        
        echo -e "${GREEN}✔${NC} Backup restored"
    fi
fi

echo ""
echo -e "${GREEN}Uninstall complete${NC}"
echo -e "Your shell is still set to ${CYAN}$SHELL${NC}"
echo -e "To change back to bash: ${YELLOW}chsh -s /bin/bash${NC}"
