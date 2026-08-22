#!/bin/sh
# (A linha shebang acima é opcional para scripts sourced, mas boa para editores)

export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-nano}"
export SUDO_EDITOR="${SUDO_EDITOR:-nano}"

export LESS="-R"

alias sudo='sudo EDITOR=$EDITOR VISUAL=$VISUAL'

export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-}"

# =====================================================================
# CHECAGEM DE SHELL INTERATIVO
# Se não for interativo (ex: scripts, scp), sai aqui para não quebrar nada.
# =====================================================================
if [ -z "${PS1:-}" ]; then
    return 0 2>/dev/null || exit 0
fi

# =====================================================================
# CONFIGURAÇÃO DO STARSHIP (PROMPT)
# Requer fonte com ícones no terminal; a imagem prioriza FiraCode Nerd Font via fontconfig.
# =====================================================================
if command -v starship >/dev/null 2>&1; then
    # Define o tema global do sistema APENAS se o usuário não tiver o seu próprio
    USER_STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
    
    if [ ! -f "$USER_STARSHIP_CONFIG" ] && [ -f "/usr/share/starship/starship.toml" ]; then
        export STARSHIP_CONFIG="/usr/share/starship/starship.toml"
    fi
    
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(starship init bash)"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(starship init zsh)"
    fi
fi

# =====================================================================
# FASTFETCH (BOAS VINDAS)
# =====================================================================
if command -v fastfetch >/dev/null 2>&1 && [ -z "${FASTFETCH_SHOWN:-}" ]; then
    export FASTFETCH_SHOWN=1
    fastfetch
fi
