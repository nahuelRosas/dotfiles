#!/bin/zsh
# ==============================================================================
# Lazy Loaders - Defer loading of slow tools until first use
# ==============================================================================

# ==============================================================================
# NVM (Node Version Manager)
# Loading NVM adds ~300ms to shell startup. This defers it until needed.
# ==============================================================================
_nvm_loaded=0

_load_nvm() {
    if [[ $_nvm_loaded -eq 0 ]]; then
        _nvm_loaded=1
        unset -f node npm npx nvm pnpm yarn
        
        export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
    fi
}

# Lazy load functions for Node tools
node() { _load_nvm; node "$@"; }
npm() { _load_nvm; npm "$@"; }
npx() { _load_nvm; npx "$@"; }
nvm() { _load_nvm; nvm "$@"; }
pnpm() { _load_nvm; pnpm "$@"; }
yarn() { _load_nvm; yarn "$@"; }

# Global npm packages (installed via npm install -g)
firebase() { _load_nvm; firebase "$@"; }
vercel() { _load_nvm; vercel "$@"; }
netlify() { _load_nvm; netlify "$@"; }
tsc() { _load_nvm; tsc "$@"; }
ts-node() { _load_nvm; ts-node "$@"; }

# ==============================================================================
# CONDA (Anaconda/Miniconda)
# Conda initialization adds ~200ms. Defer until used.
# ==============================================================================
_conda_loaded=0

_load_conda() {
    if [[ $_conda_loaded -eq 0 ]]; then
        _conda_loaded=1
        unset -f conda mamba
        
        local CONDA_DIR="${CONDA_DIR:-$HOME/anaconda3}"
        [[ -d "$HOME/miniconda3" ]] && CONDA_DIR="$HOME/miniconda3"
        
        if [[ -f "$CONDA_DIR/etc/profile.d/conda.sh" ]]; then
            source "$CONDA_DIR/etc/profile.d/conda.sh"
        else
            export PATH="$CONDA_DIR/bin:$PATH"
        fi
        
        # Initialize conda for shell
        local conda_hook="$("$CONDA_DIR/bin/conda" shell.zsh hook 2>/dev/null)"
        [[ $? -eq 0 ]] && eval "$conda_hook"
    fi
}

conda() { _load_conda; conda "$@"; }
mamba() { _load_conda; mamba "$@"; }

# ==============================================================================
# PYENV
# ==============================================================================
_pyenv_loaded=0

_load_pyenv() {
    if [[ $_pyenv_loaded -eq 0 ]] && [[ -d "$HOME/.pyenv" ]]; then
        _pyenv_loaded=1
        unset -f pyenv
        
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)" 2>/dev/null || true
    fi
}

pyenv() { _load_pyenv; pyenv "$@"; }

# ==============================================================================
# RBENV (Ruby Version Manager)
# ==============================================================================
_rbenv_loaded=0

_load_rbenv() {
    if [[ $_rbenv_loaded -eq 0 ]] && command -v rbenv &>/dev/null; then
        _rbenv_loaded=1
        unset -f rbenv
        eval "$(rbenv init -)"
    fi
}

rbenv() { _load_rbenv; rbenv "$@"; }

# ==============================================================================
# SDKMAN (Java/Kotlin/Gradle)
# ==============================================================================
_sdkman_loaded=0

_load_sdkman() {
    if [[ $_sdkman_loaded -eq 0 ]]; then
        _sdkman_loaded=1
        unset -f sdk
        
        export SDKMAN_DIR="$HOME/.sdkman"
        [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
    fi
}

sdk() { _load_sdkman; sdk "$@"; }

# ==============================================================================
# RUST (Cargo)
# ==============================================================================
_rust_loaded=0

_load_rust() {
    if [[ $_rust_loaded -eq 0 ]] && [[ -f "$HOME/.cargo/env" ]]; then
        _rust_loaded=1
        unset -f cargo rustc rustup
        source "$HOME/.cargo/env"
    fi
}

cargo() { _load_rust; cargo "$@"; }
rustc() { _load_rust; rustc "$@"; }
rustup() { _load_rust; rustup "$@"; }

# ==============================================================================
# GO
# ==============================================================================
if [[ -d "/usr/local/go" ]] && [[ ! ":$PATH:" == *":/usr/local/go/bin:"* ]]; then
    export PATH="/usr/local/go/bin:$PATH"
fi
if [[ -d "$HOME/go/bin" ]] && [[ ! ":$PATH:" == *":$HOME/go/bin:"* ]]; then
    export PATH="$HOME/go/bin:$PATH"
fi

# ==============================================================================
# BUN
# ==============================================================================
_bun_loaded=0

_load_bun() {
    if [[ $_bun_loaded -eq 0 ]] && [[ -d "$HOME/.bun" ]]; then
        _bun_loaded=1
        unset -f bun bunx
        
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
    fi
}

bun() { _load_bun; bun "$@"; }
bunx() { _load_bun; bunx "$@"; }

# ==============================================================================
# DENO
# ==============================================================================
if [[ -d "$HOME/.deno" ]]; then
    export DENO_INSTALL="$HOME/.deno"
    [[ ! ":$PATH:" == *":$DENO_INSTALL/bin:"* ]] && export PATH="$DENO_INSTALL/bin:$PATH"
fi

# ==============================================================================
# GCLOUD (Google Cloud SDK)
# ==============================================================================
_gcloud_loaded=0

_load_gcloud() {
    if [[ $_gcloud_loaded -eq 0 ]]; then
        _gcloud_loaded=1
        unset -f gcloud gsutil bq
        
        local gcloud_path="$HOME/google-cloud-sdk"
        [[ -f "$gcloud_path/path.zsh.inc" ]] && source "$gcloud_path/path.zsh.inc"
        [[ -f "$gcloud_path/completion.zsh.inc" ]] && source "$gcloud_path/completion.zsh.inc"
    fi
}

gcloud() { _load_gcloud; gcloud "$@"; }
gsutil() { _load_gcloud; gsutil "$@"; }
bq() { _load_gcloud; bq "$@"; }

# ==============================================================================
# AWS CLI
# ==============================================================================
# AWS CLI is fast enough to not need lazy loading, but we set up completion
if command -v aws &>/dev/null; then
    complete -C '/usr/local/bin/aws_completer' aws 2>/dev/null || true
fi

# ==============================================================================
# KUBECTL
# ==============================================================================
_kubectl_loaded=0

_load_kubectl() {
    if [[ $_kubectl_loaded -eq 0 ]] && command -v kubectl &>/dev/null; then
        _kubectl_loaded=1
        source <(kubectl completion zsh)
    fi
}

# Load kubectl completion on first tab-complete, not on first use
# This is done via zstyle instead of lazy function
if command -v kubectl &>/dev/null; then
    # Only load completion when actually completing kubectl commands
    zstyle ':completion:*:*:kubectl:*' script =(kubectl completion zsh)
fi

# ==============================================================================
# FLUTTER
# ==============================================================================
_flutter_loaded=0

_load_flutter() {
    if [[ $_flutter_loaded -eq 0 ]] && [[ -d "$HOME/.flutter" ]]; then
        _flutter_loaded=1
        unset -f flutter dart
        
        export FLUTTER_HOME="$HOME/.flutter"
        export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
        export PATH="$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
        
        # Disable analytics
        export FLUTTER_DISABLE_ANALYTICS=true
    fi
}

flutter() { _load_flutter; flutter "$@"; }
dart() { _load_flutter; dart "$@"; }
