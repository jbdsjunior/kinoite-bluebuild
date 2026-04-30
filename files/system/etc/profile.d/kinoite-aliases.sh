#!/bin/bash
# Global aliases for kinoite-bluebuild post-installation routines
# Install: copy to /etc/profile.d/kinoite-aliases.sh (system-wide)
#          or source from ~/.bashrc / ~/.zshrc (user-level)

# Global alias: update -> topgrade (aligns with systemd service flags)
alias update='topgrade -cy --no-ask-retry --auto-retry 2 --only system flatpak'
alias update-all='topgrade -cy --no-ask-retry --auto-retry 2'
# --- bootc / rpm-ostree ---
# Note: bootc is the primary runtime. rpm-ostree is used for kargs because
# bootc delegates this operation to the rpm-ostree backend on OCI-based images.
alias rollback='sudo bootc rollback'
alias kargs='rpm-ostree kargs'
alias kargs-edit='sudo rpm-ostree kargs --editor'
alias config-diff='sudo ostree admin config-diff'

# --- update timers ---
alias update-status='systemctl --user status topgrade-update.timer'

# --- services ---
alias fw-status='sudo systemctl status firewalld'
alias dns-status='sudo systemctl status systemd-resolved'
alias kvm-status='sudo systemctl status libvirtd'

# --- secure boot (nvidia variant) ---
alias secureboot-enroll='ujust enroll-secure-boot-key'

# --- tmpfiles (BTRFS NoCOW) ---
alias tmpfiles-system='sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf'
alias tmpfiles-user='systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf'

# --- combo shortcuts ---
alias status-all='update-status && fw-status && dns-status'
alias kvm-setup='sudo setup-kvm.sh'
