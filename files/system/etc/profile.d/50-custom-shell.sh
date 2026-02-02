# Global Shell Configuration for Kinoite

# Initialize Starship if installed
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# Run fastfetch on interactive login
if [[ $- == *i* ]] && command -v fastfetch &> /dev/null; then
    if [ -z "$FASTFETCH_RAN" ]; then
        fastfetch
        export FASTFETCH_RAN=1
    fi
fi