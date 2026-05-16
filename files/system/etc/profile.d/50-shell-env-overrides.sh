#!/bin/sh
# POSIX compliant shell initialization
# System-wide environment overrides for interactive shells

# Set default editor (respects user override if already set)
export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-nano}"

# ROCm/HIP defaults for local AI tooling on AMD systems
[ -d /usr/lib64/rocm ] && export ROCM_PATH="${ROCM_PATH:-/usr/lib64/rocm}"
[ -d /usr/lib64/rocm ] && export HIP_PATH="${HIP_PATH:-/usr/lib64/rocm}"

# RDNA2 compatibility override for toolchains that still require explicit gfx target.
# Keep opt-in by default to avoid impacting workloads where auto-detection already works.
export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-}"

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
