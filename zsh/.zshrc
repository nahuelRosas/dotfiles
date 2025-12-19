#!/bin/zsh
# ==============================================================================
# INSTANT PROMPT - Powerlevel10k (MUST be first)
# ==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
# OH-MY-ZSH CONFIGURATION
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins (loaded by Oh-My-Zsh)
plugins=(
    git
    extract
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-history-substring-search
    zsh-z
    zsh-vi-mode
)

# Disable auto-update prompt (we handle updates manually)
zstyle ':omz:update' mode disabled

# Load Oh-My-Zsh
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# ==============================================================================
# HISTORY CONFIGURATION
# ==============================================================================
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"

# Create history directory if needed
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"

setopt EXTENDED_HISTORY          # Write timestamp to history
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first
setopt HIST_IGNORE_DUPS          # Ignore consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicate entries
setopt HIST_IGNORE_SPACE         # Ignore commands starting with space
setopt HIST_FIND_NO_DUPS         # No duplicates in search
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks
setopt HIST_VERIFY               # Show before executing from history
setopt SHARE_HISTORY             # Share history between sessions
setopt INC_APPEND_HISTORY        # Add immediately, not at shell exit

# ==============================================================================
# COMPLETION CONFIGURATION (with caching)
# ==============================================================================
autoload -Uz compinit

# Only regenerate compinit once per day
_comp_files=(${ZDOTDIR:-$HOME}/.zcompdump(Nm-20))
if (( $#_comp_files )); then
    compinit -C
else
    compinit
fi
unset _comp_files

# Completion styling
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Cache completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# ==============================================================================
# KEY BINDINGS
# ==============================================================================
bindkey -e  # Emacs mode

# Home/End/Delete
bindkey '\e[H'  beginning-of-line
bindkey '\e[F'  end-of-line
bindkey '\e[3~' delete-char

# History search with arrows
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Ctrl+arrows for word navigation
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ==============================================================================
# SOURCE MODULAR CONFIGS
# ==============================================================================
_source_if_exists() {
    [[ -f "$1" ]] && source "$1"
}

_source_if_exists "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/aliases.zsh"
_source_if_exists "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/functions.zsh"
_source_if_exists "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/lazy-loaders.zsh"
_source_if_exists "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/completions.zsh"

# ==============================================================================
# TOOL INTEGRATIONS (Fast)
# ==============================================================================
# FZF
_source_if_exists ~/.fzf.zsh

# Zoxide (fast cd)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# Direnv (project-specific env)
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# Colorls tab completion
if command -v colorls &>/dev/null; then
    source $(dirname $(gem which colorls 2>/dev/null))/../tab_complete.sh 2>/dev/null || true
fi

# ==============================================================================
# POWERLEVEL10K CONFIG
# ==============================================================================
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Finalize instant prompt
command -v p10k-instant-prompt-finalize &>/dev/null && p10k-instant-prompt-finalize

# ==============================================================================
# PERFORMANCE: Compile zshrc in background
# ==============================================================================
{
    local zshrc="$HOME/.zshrc"
    if [[ ! -f "${zshrc}.zwc" ]] || [[ "$zshrc" -nt "${zshrc}.zwc" ]]; then
        zcompile "$zshrc"
    fi
} &!
