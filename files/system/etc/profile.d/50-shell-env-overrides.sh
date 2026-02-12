# Global Shell Configuration for Kinoite

# Locale fallback: keep a bilingual workflow (pt_BR + English docs/messages)
if [ -z "${LANG:-}" ]; then
    export LANG=pt_BR.UTF-8
fi
if [ -z "${LC_MESSAGES:-}" ]; then
    export LC_MESSAGES=en_US.UTF-8
fi

# Initialize Starship if installed
if [ -n "${BASH_VERSION:-}" ] && [ -n "${PS1:-}" ] && command -v starship >/dev/null 2>&1; then
    if [ -f /etc/starship.toml ]; then
        export STARSHIP_CONFIG=/etc/starship.toml
    fi
    eval "$(starship init bash)"
fi

# Bash completion and suggestion quality-of-life defaults
if [ -n "${BASH_VERSION:-}" ] && [ -n "${PS1:-}" ]; then
    # Better interactive shell ergonomics
    shopt -s checkwinsize histappend cmdhist autocd

    # Keep a useful, persistent command history
    export HISTSIZE=10000
    export HISTFILESIZE=200000
    export HISTCONTROL=ignoreboth:erasedups
    export HISTIGNORE="ls:bg:fg:history:clear:exit"
    export HISTTIMEFORMAT="%F %T "
    case ";${PROMPT_COMMAND:-};" in
        *";history -a;"*) ;;
        *) PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }history -a" ;;
    esac

    # Pager defaults for readable output
    export PAGER=less
    export LESS='-R -F -X -M -i -J'

    for bash_completion in /usr/share/bash-completion/bash_completion /etc/bash_completion; do
        if [ -r "$bash_completion" ]; then
            # shellcheck disable=SC1090
            . "$bash_completion"
            break
        fi
    done

    bind "set completion-ignore-case on"
    bind "set show-all-if-ambiguous on"
    bind "set menu-complete-display-prefix on"
    bind "set mark-symlinked-directories on"

    # Load alias definitions from dedicated files
    for alias_file in /etc/profile.d/aliases.d/*.sh; do
        [ -r "$alias_file" ] || continue
        # shellcheck disable=SC1090
        . "$alias_file"
    done

    # Create and enter a directory in one command
    mkcd() {
        [ -n "$1" ] || return 1
        mkdir -p -- "$1" && cd -- "$1"
    }
fi

# Run fastfetch on interactive login
if [ -n "${PS1:-}" ] && command -v fastfetch >/dev/null 2>&1; then
    if [ -z "$FASTFETCH_RAN" ]; then
        fastfetch
        export FASTFETCH_RAN=1
    fi
fi
