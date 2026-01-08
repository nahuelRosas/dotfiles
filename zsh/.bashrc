#!/bin/bash
if [ -n "$ZSH_VERSION" ]; then
    return
fi

if command -v zsh >/dev/null 2>&1; then
    export SHELL=$(command -v zsh)
    exec zsh "$@"
fi

