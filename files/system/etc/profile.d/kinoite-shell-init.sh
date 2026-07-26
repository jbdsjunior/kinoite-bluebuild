if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG="${STARSHIP_CONFIG:-/usr/share/starship/starship.toml}"
  case "$-" in
    *i*) eval "$(starship init bash 2>/dev/null)" ;;
  esac
fi
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null)"
fi
