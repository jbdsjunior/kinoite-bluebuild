# Initialize Starship if installed
if [ -n "${BASH_VERSION:-}" ] && [ -n "${PS1:-}" ] && command -v starship >/dev/null 2>&1; then
    if [ -f /etc/starship.toml ]; then
        export STARSHIP_CONFIG=/etc/starship.toml
    fi
    eval "$(starship init bash)"
fi