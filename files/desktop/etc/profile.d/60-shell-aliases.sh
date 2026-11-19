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

alias update='topgrade -cy --no-ask-retry --auto-retry 2 --only system flatpak'
alias update-all='topgrade -cy --no-ask-retry --auto-retry 2'
alias sysup='sudo bootc update'

# Critical flow: disaster recovery and deployment rollback
alias rollback='sudo bootc rollback'
alias kargs='rpm-ostree kargs'
alias kargs-edit='sudo rpm-ostree kargs --editor'
alias config-diff='sudo ostree admin config-diff'
alias status-ostree='rpm-ostree status'
alias status-bootc='sudo bootc status'

alias status-fw='systemctl status firewalld'
alias status-dns='systemctl status systemd-resolved'
alias status-kvm='systemctl --user status virtqemud-session.service'
alias status-tailscale='tailscale status'
alias status-podman='systemctl status podman-auto-update.timer'
alias status-podman-user='systemctl --user status podman-auto-update.timer'
alias status-flatpak-system='systemctl status flatpak-system-update.timer'
alias status-flatpak-user='systemctl --user status flatpak-user-update.timer'
alias status-bootc-update='systemctl status bootc-fetch-apply-updates.timer'
alias status-maintenance='systemctl status kinoite-maintenance.timer'
alias status-maintenance-user='systemctl --user status kinoite-user-maintenance.timer'
alias status-rclone='systemctl --user status "rclone@*"'
alias logs-rclone='journalctl --user -u "rclone@*" -f'
alias restart-rclone='systemctl --user restart "rclone@*"'

alias gpu-top='nvtop'

alias podman-cleanup='podman system prune -af && podman volume prune -f'
alias distrobox-list='distrobox list'
alias podman-ps='podman ps -a'

# System optimization and maintenance script
alias optimize='kinoite-optimize'
alias sys-optimize='sudo kinoite-optimize'
alias setup-tpm='sudo kinoite-setup-tpm'
