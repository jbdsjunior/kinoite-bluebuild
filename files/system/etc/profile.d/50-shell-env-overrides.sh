#!/bin/sh
# POSIX compliant shell initialization

if [ -n "${BASH_VERSION:-}" ] && [ -n "${PS1:-}" ]; then
    if [ -r /usr/share/bash-completion/bash_completion ] && [ -z "${BASH_COMPLETION_VERSINFO:-}" ]; then
        # shellcheck disable=SC1091
        . /usr/share/bash-completion/bash_completion
    fi
    bind 'set show-all-if-ambiguous on'
    bind 'set completion-ignore-case on'
    bind 'set menu-complete-display-prefix on'
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
fi

if command -v starship >/dev/null 2>&1; then
    [ -f /usr/share/starship/starship.toml ] && export STARSHIP_CONFIG=/usr/share/starship/starship.toml
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(starship init bash)"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(starship init zsh)"
    fi
fi

if command -v fastfetch >/dev/null 2>&1 && [ -z "${FASTFETCH_SHOWN:-}" ]; then
    export FASTFETCH_SHOWN=1
    fastfetch
fi
