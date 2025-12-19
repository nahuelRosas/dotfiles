#!/bin/bash
# ==============================================================================
# Installation Verification Script
# ==============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Dotfiles Installation Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Counters
PASSED=0
FAILED=0
WARNINGS=0

check() {
    local name="$1"
    local check_cmd="$2"
    local version_cmd="${3:-}"
    
    if eval "$check_cmd" &>/dev/null; then
        if [[ -n "$version_cmd" ]]; then
            local version=$(eval "$version_cmd" 2>/dev/null | head -1)
            echo -e "${GREEN}✔${NC} $name ${CYAN}($version)${NC}"
        else
            echo -e "${GREEN}✔${NC} $name"
        fi
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✖${NC} $name"
        ((FAILED++))
        return 1
    fi
}

warn() {
    local name="$1"
    local msg="$2"
    echo -e "${YELLOW}⚠${NC} $name - $msg"
    ((WARNINGS++))
}

# ==============================================================================
# Shell
# ==============================================================================
echo -e "${BOLD}Shell${NC}"
echo ""
check "Zsh" "command -v zsh" "zsh --version | cut -d' ' -f2"
check "Oh-My-Zsh" "[[ -d ~/.oh-my-zsh ]]"
check "Powerlevel10k" "[[ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]]"
check "zsh-syntax-highlighting" "[[ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]]"
check "zsh-autosuggestions" "[[ -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]]"
echo ""

# ==============================================================================
# Git
# ==============================================================================
echo -e "${BOLD}Git & Version Control${NC}"
echo ""
check "Git" "command -v git" "git --version | cut -d' ' -f3"
check "Git user.name" "[[ -n \$(git config --global user.name) ]]"
check "Git user.email" "[[ -n \$(git config --global user.email) ]]"
check "Git commit.gpgsign" "[[ \$(git config --global commit.gpgsign) == 'true' ]]"
check "GitHub CLI" "command -v gh" "gh --version | head -1 | cut -d' ' -f3"
check "Delta (diff)" "command -v delta" "delta --version | cut -d' ' -f2"
check "Lazygit" "command -v lazygit" "lazygit --version | cut -d' ' -f6 | tr -d ','"
echo ""

# ==============================================================================
# GPG & SSH
# ==============================================================================
echo -e "${BOLD}Security${NC}"
echo ""
check "GPG" "command -v gpg" "gpg --version | head -1 | awk '{print \$3}'"
check "GPG key exists" "gpg --list-secret-keys 2>/dev/null | grep -q sec"
check "SSH key exists" "ls ~/.ssh/*.pub &>/dev/null"

# Check GPG email vs Git email
GIT_EMAIL=$(git config --global user.email 2>/dev/null)
GPG_EMAIL=$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep -oP '(?<=<)[^>]+(?=>)' | head -1)
if [[ -n "$GIT_EMAIL" && -n "$GPG_EMAIL" && "$GIT_EMAIL" != "$GPG_EMAIL" ]]; then
    warn "GPG/Git email mismatch" "Git: $GIT_EMAIL, GPG: $GPG_EMAIL"
fi
echo ""

# ==============================================================================
# CLI Tools
# ==============================================================================
echo -e "${BOLD}CLI Tools${NC}"
echo ""
check "bat" "command -v bat" "bat --version | cut -d' ' -f2"
check "lsd" "command -v lsd" "lsd --version | cut -d' ' -f2"
check "fd" "command -v fd" "fd --version | cut -d' ' -f2"
check "ripgrep" "command -v rg" "rg --version | head -1 | cut -d' ' -f2"
check "fzf" "command -v fzf" "fzf --version | cut -d' ' -f1"
check "zoxide" "command -v zoxide" "zoxide --version | cut -d' ' -f2"
check "jq" "command -v jq" "jq --version"
check "btop" "command -v btop" "btop --version | cut -d' ' -f3"
echo ""

# ==============================================================================
# Development
# ==============================================================================
echo -e "${BOLD}Development${NC}"
echo ""
check "Node.js" "[[ -d ~/.nvm ]] || command -v node" "node --version 2>/dev/null || echo 'via NVM'"
check "NVM" "[[ -d ~/.nvm ]]"
check "Docker" "command -v docker" "docker --version | cut -d' ' -f3 | tr -d ','"
check "Docker Compose" "docker compose version" "docker compose version --short"
echo ""

# ==============================================================================
# Cloud CLIs (Optional)
# ==============================================================================
echo -e "${BOLD}Cloud CLIs (optional)${NC}"
echo ""
if command -v aws &>/dev/null; then
    check "AWS CLI" "command -v aws" "aws --version | cut -d' ' -f1 | cut -d'/' -f2"
else
    echo -e "${YELLOW}○${NC} AWS CLI (not installed)"
fi
if command -v gcloud &>/dev/null; then
    check "Google Cloud" "command -v gcloud" "gcloud --version 2>/dev/null | head -1 | awk '{print \$4}'"
else
    echo -e "${YELLOW}○${NC} Google Cloud SDK (not installed)"
fi
if command -v firebase &>/dev/null; then
    check "Firebase" "command -v firebase" "firebase --version"
else
    echo -e "${YELLOW}○${NC} Firebase CLI (not installed)"
fi
if command -v kubectl &>/dev/null; then
    check "kubectl" "command -v kubectl" "kubectl version --client --short 2>/dev/null | cut -d' ' -f3"
else
    echo -e "${YELLOW}○${NC} kubectl (not installed)"
fi
echo ""

# ==============================================================================
# Symlinks
# ==============================================================================
echo -e "${BOLD}Symlinks${NC}"
echo ""
check ".zshrc symlink" "[[ -L ~/.zshrc ]]"
check ".gitconfig symlink" "[[ -L ~/.gitconfig ]]"
check "Kitty config" "[[ -L ~/.config/kitty/kitty.conf ]] || [[ -f ~/.config/kitty/kitty.conf ]]"
echo ""

# ==============================================================================
# Summary
# ==============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${RED}Failed:${NC} $FAILED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo ""

if [[ $FAILED -eq 0 && $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}🎉 All checks passed!${NC}"
elif [[ $FAILED -eq 0 ]]; then
    echo -e "${YELLOW}⚠ Installation complete with warnings${NC}"
else
    echo -e "${RED}❌ Some components are missing${NC}"
    echo ""
    echo "Run the install script to fix missing components:"
    echo "  cd ~/dotfiles && ./install.sh"
fi
echo ""
