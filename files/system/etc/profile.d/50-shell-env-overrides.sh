#!/bin/sh

# Critical flow: bypass non-interactive shell sessions
case "$-" in
    *i*) ;;
      *) return 0 2>/dev/null || exit 0 ;;
esac

export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-nano}"
export SUDO_EDITOR="${SUDO_EDITOR:-nano}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--R}"
export COLORTERM="${COLORTERM:-truecolor}"

# Critical flow: AMD Navi 23 ROCm compatibility override
export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-10.3.0}"
export AMD_VULKAN_ICD="${AMD_VULKAN_ICD:-RADV}"

export FREETYPE_PROPERTIES="${FREETYPE_PROPERTIES:-cff:no-stem-darkening=0 autofitter:no-stem-darkening=0}"
export ELECTRON_OZONE_PLATFORM_HINT="${ELECTRON_OZONE_PLATFORM_HINT:-auto}"

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height 40% --layout=reverse --border --inline-info}"
if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND="${FZF_DEFAULT_COMMAND:-fd --type f --strip-cwd-prefix --hidden --follow --exclude .git}"
    export FZF_CTRL_T_COMMAND="${FZF_CTRL_T_COMMAND:-$FZF_DEFAULT_COMMAND}"
    export FZF_ALT_C_COMMAND="${FZF_ALT_C_COMMAND:-fd --type d --strip-cwd-prefix --hidden --follow --exclude .git}"
elif command -v fdfind >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND="${FZF_DEFAULT_COMMAND:-fdfind --type f --strip-cwd-prefix --hidden --follow --exclude .git}"
    export FZF_CTRL_T_COMMAND="${FZF_CTRL_T_COMMAND:-$FZF_DEFAULT_COMMAND}"
    export FZF_ALT_C_COMMAND="${FZF_ALT_C_COMMAND:-fdfind --type d --strip-cwd-prefix --hidden --follow --exclude .git}"
fi

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

if command -v zoxide >/dev/null 2>&1; then
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(zoxide init bash)"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(zoxide init zsh)"
    fi
fi

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

# Critical flow: display fastfetch once per interactive terminal session
if [ -t 1 ] && command -v fastfetch >/dev/null 2>&1 && [ -z "${FASTFETCH_SHOWN:-}" ]; then
    export FASTFETCH_SHOWN=1
    fastfetch
fi
