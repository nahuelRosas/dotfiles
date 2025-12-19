#!/bin/zsh
# ==============================================================================
# Aliases - Organized by Category
# ==============================================================================

# ==============================================================================
# NAVIGATION
# ==============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# ==============================================================================
# LISTING (with modern tools)
# ==============================================================================
# LSD - LSDeluxe
alias ls='lsd --group-dirs=first'
alias l='lsd --group-dirs=first'
alias ll='lsd -lh --group-dirs=first --color=auto'
alias la='lsd -lah --group-dirs=first --color=auto'
alias lt='lsd --tree --depth=2'
alias lta='lsd --tree --depth=2 -a'

# Colorls (alternative)
alias lc='colorls -al'
alias lct='colorls --tree'

# ==============================================================================
# FILE OPERATIONS
# ==============================================================================
alias cat='bat --paging=never'
alias catp='bat'  # With pager
alias less='bat --paging=always'

alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -I --preserve-root'
alias mkdir='mkdir -pv'

alias ln='ln -iv'
alias chmod='chmod --preserve-root'
alias chown='chown --preserve-root'
alias chgrp='chgrp --preserve-root'

# ==============================================================================
# GREP & SEARCH
# ==============================================================================
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Ripgrep
alias rg='rg --smart-case'
alias rgi='rg --ignore-case'

# Find
alias fd='fd --hidden --follow'

# ==============================================================================
# GIT
# ==============================================================================
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'
alias gf='git fetch --all --prune'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gds='git diff --staged'
alias glog='git log --oneline --graph --decorate -n 20'
alias gloga='git log --oneline --graph --decorate --all -n 30'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gm='git merge'
alias gcp='git cherry-pick'
alias grh='git reset --hard'
alias grs='git reset --soft'
alias gclean='git clean -fd'

# Lazygit
alias lg='lazygit'

# ==============================================================================
# DOCKER
# ==============================================================================
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dex='docker exec -it'
alias dlog='docker logs -f'
alias dprune='docker system prune -af'
alias dvprune='docker volume prune -f'

# ==============================================================================
# KUBERNETES (if installed)
# ==============================================================================
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kd='kubectl describe'
alias kl='kubectl logs -f'
alias kex='kubectl exec -it'

# ==============================================================================
# SYSTEM
# ==============================================================================
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias top='btop'
alias htop='btop'

# DNF
alias dnfi='sudo dnf install'
alias dnfs='dnf search'
alias dnfu='sudo dnf upgrade'
alias dnfr='sudo dnf remove'
alias dnfc='sudo dnf clean all'

# Flatpak
alias fpi='flatpak install flathub'
alias fps='flatpak search'
alias fpu='flatpak update'
alias fpr='flatpak uninstall'
alias fpl='flatpak list'

# Systemd
alias sc='systemctl'
alias scs='systemctl status'
alias sce='sudo systemctl enable'
alias scd='sudo systemctl disable'
alias scr='sudo systemctl restart'
alias scst='sudo systemctl start'
alias scsp='sudo systemctl stop'
alias scdr='sudo systemctl daemon-reload'
alias jctl='journalctl -xe'

# ==============================================================================
# NETWORK
# ==============================================================================
alias ip='ip -c'
alias ping='ping -c 5'
alias ports='ss -tulanp'
alias myip='curl -s ifconfig.me'
alias localip="ip route get 1 | awk '{print \$7}'"
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'

# ==============================================================================
# UTILITIES
# ==============================================================================
alias h='history'
alias hg='history | grep'
alias help='tldr'
alias c='clear'
alias q='exit'
alias reload='exec zsh'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

# Clipboard
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'

# Editor
alias e='${EDITOR:-cursor}'
alias v='nvim'
alias vim='nvim'

# ==============================================================================
# SAFETY
# ==============================================================================
alias wget='wget -c'  # Resume by default
alias please='sudo $(fc -ln -1)'  # Repeat last command with sudo
alias fuck='sudo $(fc -ln -1)'    # Same but satisfying

# Typo fixes
alias sl='ls'
alias gti='git'
alias claer='clear'
alias clera='clear'

# ==============================================================================
# DEVELOPMENT
# ==============================================================================
# Node/NPM/PNPM
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'

alias pi='pnpm install'
alias pa='pnpm add'
alias pad='pnpm add -D'
alias pr='pnpm run'
alias pd='pnpm dev'
alias pb='pnpm build'

# Python
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'

# ==============================================================================
# QUICK DIRECTORIES
# ==============================================================================
alias dl='cd ~/Downloads'
alias doc='cd ~/Documents'
alias desk='cd ~/Desktop'
alias proj='cd ~/Projects'
alias dotfiles='cd ~/dotfiles'

# ==============================================================================
# SYSTEM UPDATE (Complete)
# ==============================================================================
alias update_system='update_all_systems'
