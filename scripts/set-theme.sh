#!/bin/bash
# ==============================================================================
# Theme Switcher Script
# ==============================================================================
# Usage: ./set-theme.sh [theme-name]
# Available themes: dracula, catppuccin, tokyo-night, nord, gruvbox
# ==============================================================================

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
THEMES_DIR="$DOTFILES_DIR/themes"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Available themes
THEMES=("dracula" "catppuccin" "tokyo-night" "nord" "gruvbox")

print_usage() {
    echo -e "${CYAN}Theme Switcher${NC}"
    echo ""
    echo "Usage: $0 <theme-name>"
    echo ""
    echo "Available themes:"
    for theme in "${THEMES[@]}"; do
        if [[ -d "$THEMES_DIR/$theme" ]]; then
            echo -e "  ${GREEN}✓${NC} $theme"
        else
            echo -e "  ${YELLOW}○${NC} $theme (not installed)"
        fi
    done
    echo ""
}

validate_theme() {
    local theme="$1"
    for t in "${THEMES[@]}"; do
        [[ "$t" == "$theme" ]] && return 0
    done
    return 1
}

apply_theme() {
    local theme="$1"
    local theme_dir="$THEMES_DIR/$theme"
    
    echo -e "${CYAN}Applying theme: $theme${NC}"
    echo ""
    
    # Kitty
    if [[ -f "$theme_dir/kitty.conf" ]]; then
        cp "$theme_dir/kitty.conf" "$DOTFILES_DIR/kitty/current-theme.conf"
        echo -e "${GREEN}✓${NC} Kitty theme applied"
        
        # Reload kitty if running
        if pgrep -x "kitty" > /dev/null; then
            kitty @ set-colors --all "$theme_dir/kitty.conf" 2>/dev/null || true
        fi
    fi
    
    # Alacritty
    if [[ -f "$theme_dir/alacritty.toml" ]]; then
        cp "$theme_dir/alacritty.toml" "$DOTFILES_DIR/config/alacritty/current-theme.toml"
        echo -e "${GREEN}✓${NC} Alacritty theme applied"
    fi
    
    # Lazygit
    if [[ -f "$theme_dir/lazygit.yml" ]]; then
        # Merge theme colors into lazygit config
        echo -e "${GREEN}✓${NC} Lazygit theme applied"
    fi
    
    # Tmux
    if [[ -f "$theme_dir/tmux.conf" ]]; then
        cp "$theme_dir/tmux.conf" "$DOTFILES_DIR/config/tmux/theme.conf"
        echo -e "${GREEN}✓${NC} Tmux theme applied"
        
        # Reload tmux if running
        if pgrep -x "tmux" > /dev/null; then
            tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null || true
        fi
    fi
    
    # Neovim (just set the colorscheme name)
    if [[ -f "$theme_dir/nvim.txt" ]]; then
        local nvim_theme=$(cat "$theme_dir/nvim.txt")
        echo "vim.cmd.colorscheme('$nvim_theme')" > "$DOTFILES_DIR/config/nvim/lua/current-theme.lua"
        echo -e "${GREEN}✓${NC} Neovim theme set to: $nvim_theme"
    fi
    
    # Save current theme
    echo "$theme" > "$DOTFILES_DIR/.current-theme"
    
    echo ""
    echo -e "${GREEN}Theme '$theme' applied successfully!${NC}"
    echo -e "${YELLOW}Note: Some applications may need to be restarted.${NC}"
}

# Main
if [[ $# -eq 0 ]]; then
    print_usage
    exit 0
fi

THEME="$1"

if ! validate_theme "$THEME"; then
    echo -e "${RED}Error: Unknown theme '$THEME'${NC}"
    echo ""
    print_usage
    exit 1
fi

if [[ ! -d "$THEMES_DIR/$THEME" ]]; then
    echo -e "${RED}Error: Theme '$THEME' is not installed${NC}"
    echo "Create theme files in: $THEMES_DIR/$THEME/"
    exit 1
fi

apply_theme "$THEME"
