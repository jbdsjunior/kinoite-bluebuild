# Bash interactive UX: autocomplete + history-based suggestions
if [ -n "${BASH_VERSION:-}" ] && [ -n "${PS1:-}" ]; then
    # Open new interactive shells in ~/Downloads by default when started in $HOME.
    if [ "${PWD:-}" = "${HOME:-}" ] && [ -d "${HOME:-}/Downloads" ]; then
        cd "${HOME}/Downloads" || true
    fi

    if [ -r /usr/share/bash-completion/bash_completion ] && [ -z "${BASH_COMPLETION_VERSINFO:-}" ]; then
        # shellcheck source=/usr/share/bash-completion/bash_completion
        . /usr/share/bash-completion/bash_completion
    fi

    bind 'set show-all-if-ambiguous on'
    bind 'set completion-ignore-case on'
    bind 'set menu-complete-display-prefix on'
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'

    if command -v starship >/dev/null 2>&1; then
        if [ -f /etc/starship.toml ]; then
            export STARSHIP_CONFIG=/etc/starship.toml
        fi
        eval "$(starship init bash)"
    fi
fi
