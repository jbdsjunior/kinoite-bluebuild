#!/bin/sh

# Skip if non-interactive shell
case "$-" in
    *i*) ;;
      *) return 0 2>/dev/null || exit 0 ;;
esac

# Directory navigation and listing with Nerd Fonts icon support via eza
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons=auto --group-directories-first'
    alias ll='eza -lh --icons=auto --group-directories-first --git'
    alias la='eza -lha --icons=auto --group-directories-first --git'
    alias lt='eza --tree --icons=auto --level=2'
    alias tree='eza --tree --icons=auto'
else
    alias ls='ls --color=auto'
    alias ll='ls -l --color=auto'
    alias la='ls -la --color=auto'
fi
alias grep='grep --color=auto'

# Modern terminal utilities (bat and btop)
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --plain --paging=never'
fi

if command -v btop >/dev/null 2>&1; then
    alias top='btop'
    alias htop='btop'
fi

# Accidental file overwrite and deletion safeguards
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Shell session reload without path duplication
alias reload-profile='exec $SHELL'

# System and flatpak update aliases
alias update='topgrade -cy --no-ask-retry --auto-retry 2 --only system flatpak'
alias update-all='topgrade -cy --no-ask-retry --auto-retry 2'
alias sysup='sudo bootc update'

# Bootc and rpm-ostree management
alias rollback='sudo bootc rollback'
alias kargs='rpm-ostree kargs'
alias kargs-edit='sudo rpm-ostree kargs --editor'
alias config-diff='sudo ostree admin config-diff'
alias status-ostree='rpm-ostree status'
alias status-bootc='sudo bootc status'

# Service and timer status queries
alias status-fw='systemctl status firewalld'
alias status-dns='systemctl status systemd-resolved'
alias status-kvm='systemctl status virtqemud.socket virtqemud.service'
alias status-tailscale='tailscale status'
alias status-podman='systemctl status podman-auto-update.timer'
alias status-flatpak-system='systemctl status flatpak-system-update.timer'
alias status-flatpak-user='systemctl --user status flatpak-user-update.timer'
alias status-bootc-update='systemctl status bootc-fetch-apply-updates.timer'
alias status-soar='systemctl --user status soar-upgrade.timer'

# GPU & Hardware Diagnostics
alias gpu-top='nvtop'
alias gpu-stat='radeontop'

# BTRFS NoCOW tmpfiles application
alias tmpfiles-system='sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf'
alias tmpfiles-user='systemd-tmpfiles --user --create'
alias tmpfiles-all='sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf && systemd-tmpfiles --user --create'

# Container and VM maintenance
alias podman-cleanup='podman system prune -af && podman volume prune -f'
alias distrobox-list='distrobox list'
alias podman-ps='podman ps -a'
