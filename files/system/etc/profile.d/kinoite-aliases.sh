#!/bin/bash
alias update='topgrade -cy --no-ask-retry --auto-retry 2 --only system flatpak'
alias update-all='topgrade -cy --no-ask-retry --auto-retry 2'

alias rollback='sudo bootc rollback'
alias kargs='rpm-ostree kargs'
alias kargs-edit='sudo rpm-ostree kargs --editor'
alias config-diff='sudo ostree admin config-diff'

alias fw-status='sudo systemctl status firewalld'
alias dns-status='sudo systemctl status systemd-resolved'
alias kvm-status='sudo systemctl status libvirtd'

alias tmpfiles-system='sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf'
alias tmpfiles-user='systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf'

alias status-all='fw-status && dns-status'
alias kvm-setup='sudo setup-kvm.sh'
