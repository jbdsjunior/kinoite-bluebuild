#!/bin/sh
# POSIX compliant shell initialization
# System-wide environment overrides for interactive shells

# Set default editor
export EDITOR=nano
export VISUAL=nano

# Exit early if not running interactively to prevent breaking scp/rsync/sftp
# Profile.d scripts are sourced, so return is safe; avoid exit which would kill the parent shell
if [ -z "${PS1:-}" ]; then
    return 0 2>/dev/null
fi

# Initialize starship prompt
# Users can override by creating ~/.config/starship.toml
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
