#!/bin/bash

# System update aliases
alias update='topgrade -cy --no-ask-retry --auto-retry 2 --only system flatpak'
alias update-all='topgrade -cy --no-ask-retry --auto-retry 2'
alias sysup='sudo rpm-ostree upgrade'

# Bootc and rpm-ostree management
alias rollback='sudo bootc rollback'
alias kargs='rpm-ostree kargs'
alias kargs-edit='sudo rpm-ostree kargs --editor'
alias config-diff='sudo ostree admin config-diff'
alias ostree-status='rpm-ostree status'
alias bootc-status='bootc status'

# Service status shortcuts
alias status-fw='sudo systemctl status firewalld'
alias status-dns='sudo systemctl status systemd-resolved'
alias status-kvm='sudo systemctl status libvirtd'
alias status-podman='systemctl --user status podman-user-prune.timer'
alias status-flatpak-system='systemctl status flatpak-system-update.timer'
alias status-flatpak-user='systemctl --user status flatpak-user-update.timer'
alias status-rpm-ostree='systemctl status rpm-ostreed-automatic.timer'

# BTRFS NoCOW tmpfiles management
alias tmpfiles-system='sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf'
alias tmpfiles-user='systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf'
alias tmpfiles-all='tmpfiles-system && tmpfiles-user'

# Podman cleanup
alias podman-prune-system='sudo systemctl start podman-system-prune.service'
alias podman-prune-user='systemctl --user start podman-user-prune.service'
alias podman-cleanup='podman system prune -af && podman volume prune -f'

# Container and VM management
alias distrobox-list='distrobox list'
alias podman-ps='podman ps -a'
alias virt-manager='virt-manager'

# Quick system info
alias myip='curl -s https://api.ipify.org'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'
alias gpu-info='lspci -nn | grep -i vga'
alias cpu-info='lscpu | grep -E "Model name|CPU\\(s\\)|Architecture"'
