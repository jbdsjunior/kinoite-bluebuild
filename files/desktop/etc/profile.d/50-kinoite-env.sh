#!/bin/sh

# Critical flow: bypass non-interactive shell sessions immediately
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

# Show compact system summary once per top-level interactive terminal (skip embedded IDE terminals)
if [ -t 1 ] && [ -z "${FASTFETCH_SHOWN:-}" ] && [ "${TERM_PROGRAM:-}" != "vscode" ] && command -v fastfetch >/dev/null 2>&1; then
    export FASTFETCH_SHOWN=1
    fastfetch
fi
