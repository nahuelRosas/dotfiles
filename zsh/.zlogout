#!/bin/zsh
# ==============================================================================
# .zlogout - Cleanup on Session Exit
# ==============================================================================

# Remove sensitive commands from history
# Commands containing these patterns will be removed
if [[ -f ~/.zsh_history ]]; then
    sed -i '/password\|token\|secret\|API_KEY\|aws_secret\|private_key/Id' ~/.zsh_history 2>/dev/null
fi

# Kill SSH agent if we started it
if [[ -n "$SSH_AGENT_PID" ]]; then
    eval "$(ssh-agent -k)" &>/dev/null
fi

# Clear console for security
clear

# Optional: Remove temporary files
# rm -rf /tmp/user-$UID-* 2>/dev/null
