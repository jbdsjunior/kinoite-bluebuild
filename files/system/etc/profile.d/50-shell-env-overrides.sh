#!/bin/sh

export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-nano}"
export SUDO_EDITOR="${SUDO_EDITOR:-nano}"
export LESS="-R"
export COLORTERM="${COLORTERM:-truecolor}"

# AMD ROCm / Mesa GFX target override for RX 6600 XT (Navi 23 / gfx1032 -> 10.3.0)
export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-10.3.0}"
export AMD_VULKAN_ICD="${AMD_VULKAN_ICD:-RADV}"

# FZF Default Styling
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height 40% --layout=reverse --border --inline-info}"

case "$-" in
    *i*) ;;
      *) return 0 2>/dev/null || exit 0 ;;
esac

# Starship Prompt Integration
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

# Zoxide Smart Directory Navigation
if command -v zoxide >/dev/null 2>&1; then
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(zoxide init bash)"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(zoxide init zsh)"
    fi
fi

# FZF Shell Integration (Ctrl+R history search, Ctrl+T file find, Alt+C directory jump)
if command -v fzf >/dev/null 2>&1; then
    if [ -n "${BASH_VERSION:-}" ]; then
        if fzf --bash >/dev/null 2>&1; then
            eval "$(fzf --bash)"
        elif [ -f /usr/share/fzf/shell/key-bindings.bash ]; then
            . /usr/share/fzf/shell/key-bindings.bash
        fi
    elif [ -n "${ZSH_VERSION:-}" ]; then
        if fzf --zsh >/dev/null 2>&1; then
            eval "$(fzf --zsh)"
        fi
    fi
fi

# Fastfetch header: display once per interactive session on active TTY
if [ -t 1 ] && command -v fastfetch >/dev/null 2>&1 && [ -z "${FASTFETCH_SHOWN:-}" ]; then
    export FASTFETCH_SHOWN=1
    fastfetch
fi
