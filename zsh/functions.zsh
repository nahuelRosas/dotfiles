#!/bin/zsh
# ==============================================================================
# Functions - Utility Functions for Terminal Productivity
# ==============================================================================

# ==============================================================================
# FILE EXTRACTION - Universal extractor
# ==============================================================================
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.tar.xz)    tar xJf "$1"     ;;
            *.tar.zst)   tar --zstd -xf "$1" ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *.deb)       ar x "$1"        ;;
            *.rpm)       rpm2cpio "$1" | cpio -idmv ;;
            *.xz)        unxz "$1"        ;;
            *.lzma)      unlzma "$1"      ;;
            *)           echo "❌ '$1': unsupported format" ;;
        esac
    else
        echo "❌ '$1' is not a valid file"
    fi
}

# ==============================================================================
# NAVIGATION
# ==============================================================================

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Go up N directories
up() {
    local d=""
    local limit="${1:-1}"
    for ((i = 1; i <= limit; i++)); do
        d="../$d"
    done
    cd "$d" || return
}

# Interactive cd with zoxide + fzf
cdi() {
    local dir
    dir=$(zoxide query -l 2>/dev/null | fzf --preview 'lsd --tree --depth=2 --color=always {} 2>/dev/null || ls -la {}')
    [[ -n "$dir" ]] && cd "$dir"
}

# Back to git root
cdgr() {
    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null)
    [[ -n "$root" ]] && cd "$root" || echo "❌ You are not in a git repo"
}

# ==============================================================================
# FILE SEARCH WITH FZF
# ==============================================================================

# Find and edit file
ff() {
    local file
    file=$(fd --type f --hidden --follow --exclude .git 2>/dev/null | fzf --preview 'bat --color=always --line-range :500 {} 2>/dev/null')
    [[ -n "$file" ]] && ${EDITOR:-cursor} "$file"
}

# Find directory and cd
fcd() {
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git 2>/dev/null | fzf --preview 'lsd --tree --depth=2 --color=always {} 2>/dev/null')
    [[ -n "$dir" ]] && cd "$dir"
}

# Search in file contents
fgr() {
    local result
    result=$(rg --color=always --line-number --no-heading "${@:-}" 2>/dev/null |
        fzf --ansi --delimiter : \
            --preview 'bat --color=always {1} --highlight-line {2} 2>/dev/null' \
            --preview-window 'up,60%,border-bottom,+{2}+3/3,~3')
    
    if [[ -n "$result" ]]; then
        local file=$(echo "$result" | cut -d: -f1)
        local line=$(echo "$result" | cut -d: -f2)
        ${EDITOR:-cursor} "$file" +$line
    fi
}

# ==============================================================================
# GIT FUNCTIONS
# ==============================================================================

# Interactive branch checkout
gcob() {
    local branches branch
    branches=$(git branch -a --color=always | grep -v HEAD) &&
    branch=$(echo "$branches" |
             fzf --ansi --preview 'git log --oneline --graph --color=always $(echo {} | sed "s/.* //" | sed "s#remotes/origin/##") -- 2>/dev/null | head -50') &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/origin/##")
}

# Interactive diff viewer
gdi() {
    local file
    file=$(git diff --name-only 2>/dev/null | fzf --preview 'git diff --color=always {} 2>/dev/null')
    [[ -n "$file" ]] && git diff "$file"
}

# Commit with conventional format
gcommit() {
    local types="feat\nfix\ndocs\nstyle\nrefactor\nperf\ntest\nchore\nbuild\nci"
    local type=$(echo -e "$types" | fzf --prompt="Type: " --height=15)
    [[ -z "$type" ]] && return 1
    
    echo -n "Scope (optional, Enter to skip): "
    read scope
    
    echo -n "Message: "
    read msg
    [[ -z "$msg" ]] && return 1
    
    local commit_msg="$type"
    [[ -n "$scope" ]] && commit_msg="${type}(${scope})"
    commit_msg="${commit_msg}: ${msg}"
    
    git commit -m "$commit_msg"
}

# Show git log with fzf
glog-fzf() {
    git log --oneline --color=always |
        fzf --ansi --preview 'git show --color=always {1}' \
            --bind 'enter:execute(git show --color=always {1} | less -R)'
}

# Git stash with fzf
gstash-fzf() {
    local stash
    stash=$(git stash list | fzf --preview 'git stash show -p $(echo {} | cut -d: -f1) --color=always')
    [[ -n "$stash" ]] && git stash pop $(echo "$stash" | cut -d: -f1)
}

# ==============================================================================
# DOCKER FUNCTIONS
# ==============================================================================

# Shell into container
dshell() {
    local container
    container=$(docker ps --format '{{.Names}}' | fzf --preview 'docker inspect {} | jq ".[0].Config.Image, .[0].State"')
    [[ -n "$container" ]] && docker exec -it "$container" /bin/bash || docker exec -it "$container" /bin/sh
}

# View container logs
dlogs() {
    local container
    container=$(docker ps -a --format '{{.Names}}' | fzf --preview 'docker logs --tail 50 {} 2>&1')
    [[ -n "$container" ]] && docker logs -f "$container"
}

# Stop container interactively
dstop() {
    local container
    container=$(docker ps --format '{{.Names}}' | fzf -m --preview 'docker inspect {} | jq ".[0].State"')
    [[ -n "$container" ]] && echo "$container" | xargs docker stop
}

# Remove container interactively
drm-i() {
    local container
    container=$(docker ps -a --format '{{.Names}}' | fzf -m --preview 'docker inspect {} | jq ".[0].State"')
    [[ -n "$container" ]] && echo "$container" | xargs docker rm -f
}

# Full Docker cleanup
dclean() {
    echo "🐳 Cleaning Docker..."
    docker container prune -f
    docker image prune -af
    docker volume prune -f
    docker network prune -f
    docker builder prune -af
    echo "✅ Docker cleaned"
}

# ==============================================================================
# PROCESS MANAGEMENT
# ==============================================================================

# Kill process with fzf
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m --preview 'echo {}' | awk '{print $2}')
    [[ -n "$pid" ]] && echo "$pid" | xargs kill -${1:-9}
}

# Show ports in use
ports() {
    sudo ss -tulanp | fzf --header-lines=1
}

# Find process by port
port-process() {
    local port="${1:-}"
    [[ -z "$port" ]] && { echo "Usage: port-process <port>"; return 1; }
    sudo lsof -i :$port
}

# ==============================================================================
# SYSTEM INFORMATION
# ==============================================================================

# System info summary
sysinfo() {
    echo "╭───────────────────────────────────────╮"
    echo "│  🖥️  System                            │"
    echo "╰───────────────────────────────────────╯"
    echo " Hostname: $(hostname)"
    echo " OS:       $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo " Kernel:   $(uname -r)"
    echo " Uptime:   $(uptime -p | sed 's/up //')"
    echo ""
    echo "╭───────────────────────────────────────╮"
    echo "│  💾 Resources                         │"
    echo "╰───────────────────────────────────────╯"
    echo " CPU:      $(nproc) cores"
    echo " RAM:      $(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
    echo " Swap:     $(free -h | awk '/^Swap:/ {print $3 " / " $2}')"
    echo " Disk /:   $(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
}

# Disk space by directory
diskspace() {
    echo "📊 Disk usage in $(pwd):"
    du -h --max-depth=1 2>/dev/null | sort -hr | head -20
}

# Top memory processes
topmem() {
    echo "🧠 Top ${1:-10} processes by memory:"
    ps aux --sort=-%mem | head -n $((${1:-10} + 1))
}

# Top CPU processes
topcpu() {
    echo "⚡ Top ${1:-10} processes by CPU:"
    ps aux --sort=-%cpu | head -n $((${1:-10} + 1))
}

# ==============================================================================
# DEVELOPMENT
# ==============================================================================

# Quick HTTP server
serve() {
    local port="${1:-8000}"
    echo "🌐 Server at http://localhost:$port"
    python3 -m http.server "$port"
}

# JSON pretty print and validate
jsoncheck() {
    if [[ -f "$1" ]]; then
        cat "$1" | jq .
    else
        echo "$1" | jq .
    fi
}

# Create .gitignore from gitignore.io
gi() {
    curl -sL "https://www.toptal.com/developers/gitignore/api/$*"
}

# Generate random password
genpass() {
    local length="${1:-32}"
    openssl rand -base64 48 | tr -dc 'a-zA-Z0-9!@#$%^&*()' | head -c "$length"
    echo
}

# ==============================================================================
# QUICK EDITS
# ==============================================================================

# Edit common files
zshrc() { ${EDITOR:-cursor} ~/.zshrc && source ~/.zshrc; }
aliases() { ${EDITOR:-cursor} "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/aliases.zsh" && source ~/.zshrc; }
functions() { ${EDITOR:-cursor} "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/functions.zsh" && source ~/.zshrc; }
gitconfig() { ${EDITOR:-cursor} ~/.gitconfig; }
hosts() { sudo ${EDITOR:-cursor} /etc/hosts; }

# ==============================================================================
# SYSTEM UPDATE (Complete)
# ==============================================================================

update_all_systems() {
    echo "🔄 Updating system..."
    
    echo "\n📦 DNF packages..."
    sudo dnf upgrade -y
    
    echo "\n📱 Flatpak..."
    flatpak update -y
    
    if command -v snap &>/dev/null; then
        echo "\n📦 Snap..."
        sudo snap refresh
    fi
    
    echo "\n🐚 Oh-My-Zsh..."
    (cd ~/.oh-my-zsh && git pull --quiet)
    
    echo "\n🎨 Powerlevel10k..."
    (cd ~/.oh-my-zsh/custom/themes/powerlevel10k 2>/dev/null && git pull --quiet)
    
    echo "\n🔌 Plugins..."
    for dir in ~/.oh-my-zsh/custom/plugins/*/; do
        (cd "$dir" && git pull --quiet 2>/dev/null) || true
    done
    
    echo "\n✅ System updated!"
}

# ==============================================================================
# MISC
# ==============================================================================

# Weather
weather() {
    curl -s "wttr.in/${1:-Buenos+Aires}?format=3"
}

# Cheatsheet
cheat() {
    curl -s "cheat.sh/$1"
}

# QR code generator
qr() {
    echo "$1" | curl -F-=\<- qrenco.de
}

# Countdown timer
countdown() {
    local secs="${1:-60}"
    while [[ $secs -gt 0 ]]; do
        echo -ne "\r⏰ $secs seconds remaining...  "
        sleep 1
        ((secs--))
    done
    echo -e "\r🔔 Time's up!                    "
    # Play sound if available
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || true
}

# Stopwatch
stopwatch() {
    local start=$(date +%s)
    echo "⏱️  Stopwatch started. Ctrl+C to stop."
    while true; do
        local now=$(date +%s)
        local elapsed=$((now - start))
        printf "\r%02d:%02d:%02d" $((elapsed/3600)) $((elapsed%3600/60)) $((elapsed%60))
        sleep 1
    done
}

# Note taking
note() {
    local notes_dir="$HOME/Documents/notes"
    mkdir -p "$notes_dir"
    local note_file="$notes_dir/$(date +%Y-%m-%d).md"
    
    if [[ $# -eq 0 ]]; then
        ${EDITOR:-cursor} "$note_file"
    else
        echo "- $(date +%H:%M) $*" >> "$note_file"
        echo "📝 Note saved"
    fi
}

# TODO list
todo() {
    local todo_file="$HOME/.todo"
    
    case "${1:-}" in
        add)
            shift
            echo "[ ] $*" >> "$todo_file"
            echo "✅ Task added"
            ;;
        done)
            if [[ -f "$todo_file" ]]; then
                cat -n "$todo_file"
                echo -n "Completed task number: "
                read num
                sed -i "${num}s/\[ \]/[x]/" "$todo_file"
            fi
            ;;
        clear)
            > "$todo_file"
            echo "🗑️  List cleared"
            ;;
        *)
            [[ -f "$todo_file" ]] && cat "$todo_file" || echo "List empty"
            ;;
    esac
}

# ==============================================================================
# DOTFILES MANAGEMENT
# ==============================================================================

# Update dotfiles from repository
dotfiles_update() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
    
    if [[ ! -d "$dotfiles_dir" ]]; then
        echo "❌ Dotfiles directory not found: $dotfiles_dir"
        return 1
    fi
    
    echo "🔄 Updating dotfiles..."
    
    (
        cd "$dotfiles_dir"
        
        # Check for uncommitted changes
        if ! git diff --quiet 2>/dev/null; then
            echo "⚠️  You have uncommitted changes in dotfiles"
            echo ""
            git status --short
            echo ""
            read -q "?Stash changes and continue? [y/N]: " || { echo "\nCancelled."; return 1; }
            echo ""
            git stash push -m "Auto-stash before update"
        fi
        
        # Pull latest changes
        echo "📥 Pulling latest changes..."
        git pull --rebase
        
        # Re-source zshrc
        echo "🔃 Reloading shell configuration..."
        source ~/.zshrc
        
        echo "✅ Dotfiles updated!"
    )
}

# Verify dotfiles installation
dotfiles_verify() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
    
    if [[ -f "$dotfiles_dir/scripts/verify-install.sh" ]]; then
        bash "$dotfiles_dir/scripts/verify-install.sh"
    else
        echo "❌ Verification script not found"
        return 1
    fi
}

# Quick dotfiles status
dotfiles_status() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
    
    echo "📁 Dotfiles: $dotfiles_dir"
    echo ""
    
    if [[ -d "$dotfiles_dir/.git" ]]; then
        (
            cd "$dotfiles_dir"
            local branch=$(git branch --show-current)
            local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "?")
            local behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "?")
            
            echo "🌿 Branch: $branch"
            echo "📊 Ahead: $ahead | Behind: $behind"
            
            if ! git diff --quiet 2>/dev/null; then
                echo ""
                echo "📝 Uncommitted changes:"
                git status --short
            fi
        )
    else
        echo "⚠️  Not a git repository"
    fi
}

# ==============================================================================
# ADDITIONAL UTILITIES
# ==============================================================================

# Backup file quickly
bak() {
    [[ -z "$1" ]] && { echo "Usage: bak <file>"; return 1; }
    cp -v "$1" "${1}.bak.$(date +%Y%m%d-%H%M%S)"
}

# Restore backup (removes .bak extension)
unbak() {
    [[ -z "$1" ]] && { echo "Usage: unbak <file.bak>"; return 1; }
    local original="${1%.bak*}"
    [[ "$original" == "$1" ]] && { echo "Not a backup file"; return 1; }
    mv -v "$1" "$original"
}

# Create executable script
mkscript() {
    local script="${1:-script.sh}"
    [[ -f "$script" ]] && { echo "File exists: $script"; return 1; }
    
    cat > "$script" << 'EOF'
#!/bin/bash
set -e

# Your script here

EOF
    chmod +x "$script"
    ${EDITOR:-cursor} "$script"
}

# Git clone and cd into directory
gclone() {
    [[ -z "$1" ]] && { echo "Usage: gclone <repo-url>"; return 1; }
    git clone "$1" && cd "$(basename "$1" .git)"
}

# Benchmark command (requires hyperfine)
bench() {
    if command -v hyperfine &>/dev/null; then
        hyperfine --warmup 3 "$@"
    else
        echo "hyperfine not installed. Installing..."
        sudo dnf install -y hyperfine 2>/dev/null || cargo install hyperfine
        hyperfine --warmup 3 "$@"
    fi
}

# Load environment variables from .env file
loadenv() {
    local envfile="${1:-.env}"
    [[ ! -f "$envfile" ]] && { echo "File not found: $envfile"; return 1; }
    
    echo "Loading environment from $envfile"
    set -a
    source "$envfile"
    set +a
}

# Forward local port through SSH
portfwd() {
    [[ $# -lt 2 ]] && { echo "Usage: portfwd <remote-host> <port> [local-port]"; return 1; }
    local host="$1"
    local remote_port="$2"
    local local_port="${3:-$remote_port}"
    
    echo "Forwarding localhost:$local_port -> $host:$remote_port"
    ssh -N -L "$local_port:localhost:$remote_port" "$host"
}

# Show all terminal colors
colors() {
    for i in {0..255}; do
        printf "\x1b[38;5;${i}m%3d " "$i"
        (( (i + 1) % 16 == 0 )) && echo ""
    done
    echo ""
}

# Switch theme across all tools
set_theme() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
    bash "$dotfiles_dir/scripts/set-theme.sh" "$@"
}

# Sync dotfiles with remote
dotfiles_sync() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
    bash "$dotfiles_dir/scripts/sync-dotfiles.sh"
}

# Show system resource usage summary
sysload() {
    echo "╭───────────────────────────────────────╮"
    echo "│  📊 System Load                       │"
    echo "╰───────────────────────────────────────╯"
    echo " CPU: $(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f%%", usage}')"
    echo " RAM: $(free | awk '/Mem:/ {printf "%.1f%%", $3/$2 * 100}')"
    echo " Disk: $(df -h / | awk 'NR==2 {print $5}')"
    echo " Procs: $(ps aux | wc -l)"
}

# Kill process by port
killport() {
    [[ -z "$1" ]] && { echo "Usage: killport <port>"; return 1; }
    local pids=$(lsof -t -i ":$1" 2>/dev/null)
    
    if [[ -z "$pids" ]]; then
        echo "No process found on port $1"
    else
        echo "Killing processes on port $1: $pids"
        echo "$pids" | xargs kill -9
    fi
}

# Retry command N times
retry() {
    local max_attempts="${1:-3}"
    shift
    local count=0
    
    until "$@"; do
        exit_code=$?
        count=$((count + 1))
        
        if [[ $count -lt $max_attempts ]]; then
            echo "Attempt $count failed. Retrying..."
            sleep 1
        else
            echo "Command failed after $count attempts."
            return $exit_code
        fi
    done
}

