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

    # Helpful aliases; prefer modern tools if present
    if command -v eza >/dev/null 2>&1; then
        alias ls='eza --group-directories-first --icons=auto'
        alias ll='eza -lah --group-directories-first --icons=auto --git'
        alias la='eza -a --group-directories-first --icons=auto'
        alias lt='eza --tree --level=2 --icons=auto'
    else
        alias ls='ls --color=auto --group-directories-first'
        alias ll='ls -lah --color=auto --group-directories-first'
        alias la='ls -A --color=auto --group-directories-first'
        alias lt='ls -lah --color=auto'
    fi

    if command -v bat >/dev/null 2>&1; then
        alias cat='bat --style=plain --paging=never'
    fi

    alias grep='grep --color=auto'
    alias diff='diff --color=auto'
    alias cls='clear'
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'
    alias gst='git status -sb'
    alias gl='git log --oneline --decorate --graph -20'
    alias update='topgrade -y'
    alias ostree-status='rpm-ostree status'
    alias ostree-upgrade='rpm-ostree upgrade'

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
