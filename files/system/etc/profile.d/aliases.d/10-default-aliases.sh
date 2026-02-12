# Aliases for interactive bash sessions

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
