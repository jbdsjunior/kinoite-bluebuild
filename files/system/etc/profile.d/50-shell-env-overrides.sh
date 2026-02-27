[ -z "${BASH_VERSION:-}" ] || [ -z "${PS1:-}" ] && return

if [ "${PWD:-}" = "${HOME:-}" ] && [ -d "${HOME}/Downloads" ]; then
    cd "${HOME}/Downloads" || return 1
fi

if [ -r /usr/share/bash-completion/bash_completion ] && [ -z "${BASH_COMPLETION_VERSINFO:-}" ]; then
    # shellcheck disable=SC1091
    source /usr/share/bash-completion/bash_completion
fi

bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
bind 'set menu-complete-display-prefix on'
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

if command -v starship >/dev/null 2>&1; then
    [ -f /etc/starship.toml ] && export STARSHIP_CONFIG=/etc/starship.toml
    eval "$(starship init bash)"
fi
