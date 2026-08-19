#!/bin/sh

# ==============================================================================
# 1. Variáveis de Ambiente Globais (disponíveis para scripts e sessões interativas)
# ==============================================================================
export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-nano}"
export SUDO_EDITOR="${SUDO_EDITOR:-nano}"
export LESS="-R"

# ==============================================================================
# 2. Guarda de Interatividade: Encerra aqui se o shell NÃO for interativo
# ==============================================================================
case "$-" in
    *i*) ;;
      *) return 0 2>/dev/null ;;
esac

# ==============================================================================
# 3. Aliases Básicos do Shell
# ==============================================================================
# O espaço ao final permite que aliases subsequentes também sejam expandidos após o sudo
alias sudo='sudo '

# ==============================================================================
# 4. Prompt Customizado (Starship)
# ==============================================================================
if command -v starship >/dev/null 2>&1; then
    # Só define o fallback do sistema se o usuário NÃO possuir config própria
    if [ -z "${STARSHIP_CONFIG:-}" ] && [ ! -f "${HOME}/.config/starship.toml" ] && [ -f "/usr/share/starship/starship.toml" ]; then
        export STARSHIP_CONFIG="/usr/share/starship/starship.toml"
    fi

    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(starship init bash)"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(starship init zsh)"
    fi
fi

# ==============================================================================
# 5. Informações do Sistema (Fastfetch)
# ==============================================================================
# Executa apenas se for TTY real (evita quebra em SFTP/SCP/pipes) e se o TERM não for 'dumb'
if command -v fastfetch >/dev/null 2>&1 && [ -z "${FASTFETCH_SHOWN:-}" ]; then
    if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
        export FASTFETCH_SHOWN=1
        fastfetch
    fi
fi
