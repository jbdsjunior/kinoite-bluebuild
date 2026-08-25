#!/bin/sh

export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-nano}"
export SUDO_EDITOR="${SUDO_EDITOR:-nano}"
export LESS="-R"

if [ -n "${HSA_OVERRIDE_GFX_VERSION:-}" ]; then
    export HSA_OVERRIDE_GFX_VERSION
fi

case "$-" in
    *i*) ;;
      *) return 0 2>/dev/null || exit 0 ;;
esac

if command -v starship >/dev/null 2>&1; then
    if [ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml" ] && [ -f "/usr/share/starship/starship.toml" ]; then
        export STARSHIP_CONFIG="/usr/share/starship/starship.toml"
    fi

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
