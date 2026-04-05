#!/bin/sh
# POSIX compliant shell initialization

# Ambiente global (aplicado a todos os logins, incluindo root)
export EDITOR=nano
export VISUAL=nano
# export LANG="pt_BR.UTF-8"
# export LC_ALL="pt_BR.UTF-8"

# Exit early if not running interactively to prevent breaking scp/rsync/sftp
[ -z "${PS1:-}" ] && return

# Bash-specific interactive configurations
if [ -n "${BASH_VERSION:-}" ]; then
    if [ -r /usr/share/bash-completion/bash_completion ] && [ -z "${BASH_COMPLETION_VERSINFO:-}" ]; then
        # shellcheck disable=SC1091
        . /usr/share/bash-completion/bash_completion
    fi
    
    # shellcheck disable=SC3045
    bind 'set show-all-if-ambiguous on'
    bind 'set completion-ignore-case on'
    bind 'set menu-complete-display-prefix on'
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
fi

# Initialize starship prompt
if command -v starship >/dev/null 2>&1; then
    [ -f /usr/share/starship/starship.toml ] && export STARSHIP_CONFIG=/usr/share/starship/starship.toml
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(starship init bash)"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(starship init zsh)"
    fi
fi

# Run fastfetch once per session
if command -v fastfetch >/dev/null 2>&1 && [ -z "${FASTFETCH_SHOWN:-}" ]; then
    export FASTFETCH_SHOWN=1
    fastfetch
fi
