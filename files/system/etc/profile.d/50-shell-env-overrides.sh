#!/bin/sh

# Default editor configuration
export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-nano}"

# PAGER configuration
export PAGER="${PAGER:-less}"
export LESS="-R -F -X"

# Starship prompt initialization
if [ -n "${PS1:-}" ] && command -v starship >/dev/null 2>&1; then
    if [ -f /usr/share/starship/starship.toml ]; then
        export STARSHIP_CONFIG=/usr/share/starship/starship.toml
    fi
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(starship init bash)"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(starship init zsh)"
    elif [ -n "${FISH_VERSION:-}" ]; then
        starship init fish | source
    fi
fi

# Fastfetch system info (shown once per session)
if command -v fastfetch >/dev/null 2>&1 && [ -z "${FASTFETCH_SHOWN:-}" ]; then
    export FASTFETCH_SHOWN=1
    fastfetch --config /usr/share/fastfetch/config.jsonc 2>/dev/null || fastfetch
fi

# XDG Base Directory specification compliance
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Development environment variables
export GOPATH="${GOPATH:-$HOME/go}"
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
