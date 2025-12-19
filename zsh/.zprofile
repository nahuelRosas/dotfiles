#!/bin/zsh
# ==============================================================================
# .zprofile - Login Shell Configuration (loads once per session)
# ==============================================================================

# SSH Agent - Start only if not already running
if [[ -z "$SSH_AGENT_PID" ]] && [[ -z "$SSH_AUTH_SOCK" ]]; then
    eval "$(ssh-agent -s)" &>/dev/null
fi

# Add SSH keys quietly
ssh-add -q ~/.ssh/id_ed25519 2>/dev/null
ssh-add -q ~/.ssh/id_rsa 2>/dev/null

# Keychain integration (if available)
if command -v keychain &>/dev/null; then
    eval "$(keychain --eval --quiet id_ed25519 id_rsa 2>/dev/null)"
fi

# GPG Agent with SSH support (optional)
# Uncomment if you want to use GPG for SSH authentication
# export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
# gpgconf --launch gpg-agent

# Start gnome-keyring-daemon if in GNOME/GTK environment
if [[ -n "$DESKTOP_SESSION" ]] && [[ "$DESKTOP_SESSION" == "gnome"* ]]; then
    if command -v gnome-keyring-daemon &>/dev/null; then
        eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh 2>/dev/null)
        export SSH_AUTH_SOCK
    fi
fi
