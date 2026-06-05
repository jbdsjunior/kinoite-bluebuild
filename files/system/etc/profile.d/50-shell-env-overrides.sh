#!/bin/sh
export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-nano}"

[ -d /usr/lib64/rocm ] && export ROCM_PATH="${ROCM_PATH:-/usr/lib64/rocm}"
[ -d /usr/lib64/rocm ] && export HIP_PATH="${HIP_PATH:-/usr/lib64/rocm}"
export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-}"

if [ -z "${PS1:-}" ]; then
    return 0 2>/dev/null
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
