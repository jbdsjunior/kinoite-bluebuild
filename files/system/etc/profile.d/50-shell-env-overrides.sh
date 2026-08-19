#!/bin/sh
# =============================================================================
# 50-shell-env-overrides.sh
# Kinoite BlueBuild - Variáveis de ambiente e inicialização de shell
# =============================================================================
# Este arquivo é SOURCED pelo /etc/profile (login shells).
# NÃO é executado diretamente. O shebang acima é apenas convenção.
# =============================================================================

# --- GUARDA: Shell não-interativo? Sai imediatamente. ---
# Evita processamento desnecessário em scripts, cron, systemd, SSH sem TTY.
case "$-" in
    *i*) ;;  # Shell interativo: continua
    *)   return 0 2>/dev/null || exit 0 ;;  # Não-interativo: sai
esac

# --- GUARDA: Evita processamento duplicado ---
# Se este arquivo for sourced mais de uma vez (ex: bash --login dentro de bash),
# não repete inicializações pesadas.
if [ -n "${_KINOITE_PROFILE_LOADED:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
export _KINOITE_PROFILE_LOADED=1

# =============================================================================
# EDITORES E PAGERS
# =============================================================================
# nano como padrão (preferência do usuário PT-BR)
export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-nano}"
export SUDO_EDITOR="${SUDO_EDITOR:-nano}"
export SYSTEMD_EDITOR="${SYSTEMD_EDITOR:-nano}"

# less com cores e navegação melhorada
export PAGER="${PAGER:-less}"
export MANPAGER="${MANPAGER:-less}"
export LESS="-R -i -M -w -z-4"
# -R: interpreta cores ANSI
# -i: busca case-insensitive (shift+I para alternar)
# -M: mostra prompt detalhado (linha X de Y)
# -w: destaca temporariamente a linha alvo após busca
# -z-4: deixa 4 linhas de contexto ao rolar

# =============================================================================
# VARIÁVEIS DE SISTEMA
# =============================================================================
# Navegador padrão (usado por xdg-open, git, etc)
export BROWSER="${BROWSER:-/usr/bin/brave}"

# Cores para output de compiladores (GCC, Clang, Rust)
export GCC_COLORS="${GCC_COLORS:-error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01}"

# Rust: output colorido forçado
export CARGO_TERM_COLOR="${CARGO_TERM_COLOR:-always}"

# =============================================================================
# VARIÁVEIS XDG (XDG Base Directory Specification)
# =============================================================================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# =============================================================================
# HISTÓRICO (Bash)
# =============================================================================
if [ -n "${BASH_VERSION:-}" ]; then
    # Aumenta o histórico para 50k linhas (workstation com 64GB RAM)
    export HISTSIZE="${HISTSIZE:-50000}"
    export HISTFILESIZE="${HISTFILESIZE:-100000}"
    # Ignora comandos duplicados consecutivos e comandos começando com espaço
    export HISTCONTROL="${HISTCONTROL:-ignoreboth:erasedups}"
    # Salva timestamp no histórico
    export HISTTIMEFORMAT="${HISTTIMEFORMAT:-%F %T  }"
    # Não registra comandos de status/ls (reduz ruído)
    export HISTIGNORE="${HISTIGNORE:-ls:ll:la:l:pwd:clear:history:htop}"
fi

# =============================================================================
# CORES PARA LS (dircolors)
# =============================================================================
if command -v dircolors >/dev/null 2>&1; then
    # Usa config customizada se existir, senão usa padrão do sistema
    if [ -f "$HOME/.dircolors" ]; then
        eval "$(dircolors -b "$HOME/.dircolors" 2>/dev/null)"
    elif [ -f /etc/DIR_COLORS ]; then
        eval "$(dircolors -b /etc/DIR_COLORS 2>/dev/null)"
    fi
fi

# =============================================================================
# AMD ROCm (GPU Compute)
# =============================================================================
# A RX 6600 XT (RDNA2) suporta ROCm, mas o pacote NÃO está instalado por padrão.
# Para habilitar GPU compute (ML, Blender, etc):
#   sudo rpm-ostree install rocm-opencl rocm-hip
# Após instalar, descomente as linhas abaixo.
#
# if [ -d /usr/lib64/rocm ]; then
#     export ROCM_PATH="${ROCM_PATH:-/usr/lib64/rocm}"
#     export HIP_PATH="${HIP_PATH:-/usr/lib64/rocm}"
#     export PATH="$ROCM_PATH/bin:$PATH"
#     export LD_LIBRARY_PATH="$ROCM_PATH/lib:${LD_LIBRARY_PATH:-}"
# fi

# =============================================================================
# STARSHIP PROMPT
# =============================================================================
if command -v starship >/dev/null 2>&1; then
    # Prioridade de configuração:
    # 1. Config do usuário (~/.config/starship.toml) - permite personalização
    # 2. Config global do sistema (/usr/share/starship/starship.toml) - padrão AAA
    if [ -f "$XDG_CONFIG_HOME/starship.toml" ]; then
        export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"
    elif [ -f "/usr/share/starship/starship.toml" ]; then
        export STARSHIP_CONFIG="/usr/share/starship/starship.toml"
    fi

    # Inicializa Starship com timeout de 2 segundos
    # Se o binário estiver corrompido ou lento, não trava o shell
    if [ -n "${BASH_VERSION:-}" ]; then
        eval "$(timeout 2 starship init bash 2>/dev/null)" 2>/dev/null
    elif [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(timeout 2 starship init zsh 2>/dev/null)" 2>/dev/null
    fi
fi

# =============================================================================
# FASTFETCH (Info do sistema no login)
# =============================================================================
# Só roda UMA VEZ por sessão de login (não a cada terminal novo).
# Usa lock file em /tmp para evitar repetição.
if command -v fastfetch >/dev/null 2>&1; then
    _FASTFETCH_LOCK="/tmp/.fastfetch-shown-$(id -u)"
    if [ ! -f "$_FASTFETCH_LOCK" ]; then
        touch "$_FASTFETCH_LOCK"
        # Timeout de 3s para não travar o login se fastfetch bug
        timeout 3 fastfetch --logo-type none 2>/dev/null
    fi
    unset _FASTFETCH_LOCK
fi

# =============================================================================
# FIM
# =============================================================================