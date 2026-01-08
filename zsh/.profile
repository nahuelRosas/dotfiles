#!/bin/sh
export ENV="$HOME/.shrc"

if [ -n "$ZSH_VERSION" ]; then
    return 0
fi

if command -v zsh >/dev/null 2>&1; then
    export SHELL=$(command -v zsh)
    exec zsh "$@"
fi

