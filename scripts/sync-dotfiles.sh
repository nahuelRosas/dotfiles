#!/bin/bash
# ==============================================================================
# Dotfiles Sync Script
# ==============================================================================
# Automatically sync local dotfiles changes with the repository
# ==============================================================================

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

cd "$DOTFILES_DIR" || {
    echo -e "${RED}Error: Cannot access $DOTFILES_DIR${NC}"
    exit 1
}

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  🔄 Dotfiles Sync${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check for remote changes
echo -e "${BOLD}Checking for remote updates...${NC}"
git fetch --quiet

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})
BASE=$(git merge-base @ @{u})

if [ "$LOCAL" = "$REMOTE" ]; then
    REMOTE_STATUS="in sync"
elif [ "$LOCAL" = "$BASE" ]; then
    REMOTE_STATUS="behind"
elif [ "$REMOTE" = "$BASE" ]; then
    REMOTE_STATUS="ahead"
else
    REMOTE_STATUS="diverged"
fi

# Check for local changes
LOCAL_CHANGES=$(git status --porcelain)

echo ""

# Show status
if [[ -z "$LOCAL_CHANGES" ]]; then
    echo -e "${GREEN}✓${NC} No local changes"
else
    echo -e "${YELLOW}📝 Local changes detected:${NC}"
    echo ""
    git status --short
    echo ""
fi

case "$REMOTE_STATUS" in
    "in sync")
        echo -e "${GREEN}✓${NC} Repository is up to date with remote"
        ;;
    "behind")
        echo -e "${YELLOW}⬇${NC} Local is behind remote (pull needed)"
        ;;
    "ahead")
        echo -e "${YELLOW}⬆${NC} Local is ahead of remote (push needed)"
        ;;
    "diverged")
        echo -e "${RED}⚠${NC} Local and remote have diverged"
        ;;
esac

echo ""

# Actions menu
if [[ -n "$LOCAL_CHANGES" ]] || [[ "$REMOTE_STATUS" != "in sync" ]]; then
    echo -e "${BOLD}What would you like to do?${NC}"
    echo ""
    echo "  1) Pull remote changes"
    echo "  2) Commit and push local changes"
    echo "  3) Show full diff"
    echo "  4) Stash local changes"
    echo "  5) Exit (do nothing)"
    echo ""
    
    read -p "Select option [5]: " choice
    choice=${choice:-5}
    
    case $choice in
        1)
            echo ""
            if [[ -n "$LOCAL_CHANGES" ]]; then
                echo -e "${YELLOW}Stashing local changes first...${NC}"
                git stash push -m "Auto-stash before sync $(date +%Y%m%d-%H%M%S)"
            fi
            
            echo -e "${CYAN}Pulling remote changes...${NC}"
            git pull --rebase
            
            if git stash list | grep -q "Auto-stash before sync"; then
                echo -e "${CYAN}Restoring stashed changes...${NC}"
                git stash pop
            fi
            
            echo -e "${GREEN}✓ Sync complete!${NC}"
            ;;
        2)
            echo ""
            if [[ -z "$LOCAL_CHANGES" ]]; then
                echo -e "${YELLOW}No local changes to commit${NC}"
            else
                echo -e "${CYAN}Staging all changes...${NC}"
                git add -A
                
                echo ""
                git status --short
                echo ""
                
                read -p "Commit message: " msg
                msg=${msg:-"Update dotfiles"}
                
                git commit -m "$msg"
                
                echo ""
                echo -e "${CYAN}Pushing to remote...${NC}"
                git push
                
                echo -e "${GREEN}✓ Changes pushed successfully!${NC}"
            fi
            ;;
        3)
            echo ""
            git diff
            ;;
        4)
            if [[ -n "$LOCAL_CHANGES" ]]; then
                read -p "Stash message (optional): " stash_msg
                stash_msg=${stash_msg:-"Manual stash $(date +%Y%m%d-%H%M%S)"}
                git stash push -m "$stash_msg"
                echo -e "${GREEN}✓ Changes stashed${NC}"
            else
                echo -e "${YELLOW}No changes to stash${NC}"
            fi
            ;;
        5|*)
            echo "Exiting..."
            ;;
    esac
else
    echo -e "${GREEN}✓ Everything is in sync!${NC}"
fi

echo ""
