#!/bin/sh
# Caminho sugerido: files/system/etc/profile.d/kinoite-aliases.sh

# Ignora se não for um shell interativo
case "$-" in
    *i*) ;;
      *) return 0 2>/dev/null || exit 0 ;;
esac

# Aliases de navegação e listagem (cores padrão ativadas)
alias ls='ls --color=auto'
alias ll='ls -l --color=auto'
alias la='ls -la --color=auto'
alias grep='grep --color=auto'

# Proteção contra sobrescrita e remoção acidental de arquivos importantes
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Alias utilitário para recarregar o perfil rapidamente após edições
alias reload-profile='source /etc/profile'

# System update aliases
alias update='topgrade -cy --no-ask-retry --auto-retry 2 --only system flatpak'
alias update-all='topgrade -cy --no-ask-retry --auto-retry 2'
alias sysup='sudo rpm-ostree upgrade'

# Bootc and rpm-ostree management
alias rollback='sudo bootc rollback'
alias kargs='rpm-ostree kargs'
alias kargs-edit='sudo rpm-ostree kargs --editor'
alias config-diff='sudo ostree admin config-diff'
alias status-ostree='rpm-ostree status'
alias status-bootc='bootc status'

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
alias podman-cleanup='podman system prune -af && podman volume prune -f'

# Container and VM management
alias distrobox-list='distrobox list'
alias podman-ps='podman ps -a'
