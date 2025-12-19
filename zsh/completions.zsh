#!/bin/zsh
# ==============================================================================
# Completions - Additional completion configurations
# ==============================================================================

# ==============================================================================
# COMPLETION DIRECTORIES
# ==============================================================================
# Add custom completions directory
fpath=(
    "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions"
    "${ZDOTDIR:-$HOME}/.zfunc"
    $fpath
)

# Create directories if they don't exist
[[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions" ]] || \
    mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions"

# ==============================================================================
# TOOL-SPECIFIC COMPLETIONS
# ==============================================================================

# Docker completion
if command -v docker &>/dev/null; then
    # Docker provides its own completion, but ensure it's loaded
    if [[ -f /usr/share/zsh/vendor-completions/_docker ]]; then
        fpath=(/usr/share/zsh/vendor-completions $fpath)
    fi
fi

# Docker Compose completion
if command -v docker-compose &>/dev/null || docker compose version &>/dev/null 2>&1; then
    # Modern docker compose uses docker's completion
    :
fi

# Git completion (usually provided by git package)
# Additional git aliases completion
if command -v git &>/dev/null; then
    # Make git aliases work with completion
    __git_complete() { :; }  # Stub for compatibility
fi

# NPM completion
if command -v npm &>/dev/null && [[ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions/_npm" ]]; then
    npm completion 2>/dev/null > "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions/_npm" || true
fi

# PNPM completion
if command -v pnpm &>/dev/null; then
    # PNPM uses tabtab
    [[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && source ~/.config/tabtab/zsh/__tabtab.zsh
fi

# Rustup/Cargo completion
if command -v rustup &>/dev/null; then
    if [[ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions/_rustup" ]]; then
        rustup completions zsh > "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions/_rustup" 2>/dev/null || true
    fi
    if [[ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions/_cargo" ]]; then
        rustup completions zsh cargo > "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions/_cargo" 2>/dev/null || true
    fi
fi

# Pip completion
if command -v pip &>/dev/null; then
    eval "$(pip completion --zsh 2>/dev/null)" || true
fi

# Pipenv completion
if command -v pipenv &>/dev/null; then
    eval "$(pipenv --completion 2>/dev/null)" || true
fi

# Poetry completion
if command -v poetry &>/dev/null; then
    if [[ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions/_poetry" ]]; then
        poetry completions zsh > "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions/_poetry" 2>/dev/null || true
    fi
fi

# GitHub CLI completion
if command -v gh &>/dev/null; then
    eval "$(gh completion -s zsh 2>/dev/null)" || true
fi

# Terraform completion
if command -v terraform &>/dev/null; then
    complete -o nospace -C terraform terraform 2>/dev/null || true
fi

# Helm completion
if command -v helm &>/dev/null; then
    source <(helm completion zsh 2>/dev/null) || true
fi

# ==============================================================================
# FZF COMPLETIONS
# ==============================================================================

# Use fd with fzf for path completion
_fzf_compgen_path() {
    fd --hidden --follow --exclude ".git" . "$1"
}

# Use fd for directory completion
_fzf_compgen_dir() {
    fd --type d --hidden --follow --exclude ".git" . "$1"
}

# Advanced fzf completion for specific commands
_fzf_comprun() {
    local command=$1
    shift
    case "$command" in
        cd)           fzf --preview 'lsd --tree --depth=2 --color=always {} 2>/dev/null || tree -C {} 2>/dev/null | head -50' "$@" ;;
        export|unset) fzf --preview "eval 'echo \$'{}" "$@" ;;
        ssh)          fzf --preview 'dig {}' "$@" ;;
        *)            fzf --preview 'bat -n --color=always {} 2>/dev/null || cat {}' "$@" ;;
    esac
}

# ==============================================================================
# ADDITIONAL COMPLETION STYLES
# ==============================================================================

# Menu selection colors
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'

# Group matches and describe groups
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands

# Fuzzy matching of completions
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# Increase the number of errors based on the length of the typed word
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'

# Don't complete unavailable commands
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

# Array completion element sorting
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# Directories
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
zstyle ':completion:*' squeeze-slashes true

# History
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes

# Environment variables
zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]}#*,}%%:*}

# Populate hostname completion
zstyle -e ':completion:*:hosts' hosts 'reply=(
    ${=${=${=${${(f)"$(cat {/etc/ssh/ssh_,~/.ssh/}known_hosts(|2)(N) 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
    ${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2>/dev/null))"}%%(#${_resolve_aliases})*}
    ${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'

# Don't complete uninteresting users
zstyle ':completion:*:*:*:users' ignored-patterns \
    adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
    dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
    hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
    mailman mailnull mldonkey mysql nagios \
    named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
    operator pcap postfix postgres privoxy pulse pvm quagga radvd \
    rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs '_*'

# SSH/SCP/RSYNC
zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<-*>.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|-)-)' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# Kill completion
zstyle ':completion:*:*:*:*:processes' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single

# Man pages
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true
