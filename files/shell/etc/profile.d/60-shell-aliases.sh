#!/bin/sh

# Critical flow: bypass non-interactive shell sessions
case "$-" in
    *i*) ;;
      *) return 0 2>/dev/null || exit 0 ;;
esac

alias ls='ls --color=auto'
alias ll='ls -lh --color=auto --group-directories-first'
alias la='ls -lha --color=auto --group-directories-first'
alias grep='grep --color=auto'

# Security alert: prevent accidental file truncation or overwriting
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

alias reload-profile='exec $SHELL'

# Run Topgrade with image defaults from /usr/share/topgrade/ when user has no custom ~/.config/topgrade.toml
_kinoite_topgrade() {
    if [ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/topgrade.toml" ] && [ -f "/usr/share/topgrade/topgrade.toml" ]; then
        command topgrade --config /usr/share/topgrade/topgrade.toml "$@"
    else
        command topgrade "$@"
    fi
}

alias topgrade='_kinoite_topgrade'
alias update='_kinoite_topgrade -cy --no-ask-retry --auto-retry 2 --only system flatpak'
alias update-all='_kinoite_topgrade -cy --no-ask-retry --auto-retry 2'
alias sysup='sudo bootc upgrade'

# Critical flow: disaster recovery and deployment rollback
alias rollback='sudo bootc rollback'
alias kargs='rpm-ostree kargs'
alias kargs-edit='sudo rpm-ostree kargs --editor'
alias config-diff='sudo ostree admin config-diff'
alias status-ostree='rpm-ostree status'
alias status-bootc='sudo bootc status'

alias status-fw='systemctl status firewalld'
alias status-dns='systemctl status systemd-resolved'
alias status-tailscale='tailscale status'
alias status-flatpak-system='systemctl status flatpak-system-update.timer'
alias status-flatpak-user='systemctl --user status flatpak-user-update.timer'
alias status-bootc-update='systemctl status bootc-fetch-apply-updates.timer'
alias status-rclone='systemctl --user status "rclone@*"'
alias logs-rclone='journalctl --user -u "rclone@*" -f'
alias restart-rclone='systemctl --user restart "rclone@*"'

alias podman-cleanup='podman system prune -af && podman volume prune -f'
alias distrobox-list='distrobox list'
alias podman-ps='podman ps -a'

# System optimization and maintenance script
alias optimize='kinoite-optimize'
alias sys-optimize='sudo kinoite-optimize'
alias setup-tpm='sudo kinoite-setup-tpm'
