#!/bin/zsh
# ==============================================================================
# .zshenv - Environment Variables (loads first, always)
# ==============================================================================

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Editor
export EDITOR="cursor"
export VISUAL="cursor"
export PAGER="less"

# Locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Less configuration
export LESS="-R -F -X"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# Man pages with colors
export MANPAGER="less -R --use-color -Dd+r -Du+b"

# Path configuration (no duplicates)
typeset -U path
path=(
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/go/bin"
    "/usr/local/bin"
    $path
)

# Android SDK
if [[ -d "$HOME/Android/Sdk" ]]; then
    export ANDROID_HOME="$HOME/Android/Sdk"
    path=(
        "$ANDROID_HOME/emulator"
        "$ANDROID_HOME/tools"
        "$ANDROID_HOME/tools/bin"
        "$ANDROID_HOME/platform-tools"
        $path
    )
fi

# NVM Directory
export NVM_DIR="$HOME/.nvm"

# Java AWT fix for tiling WMs
export _JAVA_AWT_WM_NONREPARENTING=1

# GPG
export GPG_TTY=$(tty)

# FZF default options
export FZF_DEFAULT_OPTS="
    --height 40%
    --layout=reverse
    --border
    --preview-window=right:60%
    --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9
    --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9
    --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
    --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
"

# FZF use fd if available
if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
fi

# Bat theme
export BAT_THEME="Dracula"

# Ripgrep config
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
