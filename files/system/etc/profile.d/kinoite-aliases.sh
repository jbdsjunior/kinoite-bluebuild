#!/bin/sh
# Caminho sugerido no BlueBuild: files/system/etc/profile.d/kinoite-aliases.sh

# Garante que os aliases só sejam carregados em shells interativos
case "$-" in
    *i*) ;;
      *) return 0 2>/dev/null ;;
esac

# ==============================================================================
# Navegação e Manipulação Segura de Arquivos
# ==============================================================================
alias ls='ls --color=auto'
alias ll='ls -l --color=auto'
alias la='ls -la --color=auto'
alias grep='grep --color=auto'

# Proteção contra sobrescrita acidental
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Recarregar perfil (sintaxe POSIX '.' universal)
alias reload-profile='. /etc/profile'

# ==============================================================================
# Atualizações do Sistema e Flatpaks
# ==============================================================================
if command -v topgrade >/dev/null 2>&1; then
    alias update='topgrade -cy --no-ask-retry --auto-retry 2 --only system flatpak'
    alias update-all='topgrade -cy --no-ask-retry --auto-retry 2'
fi
alias sysup='sudo rpm-ostree upgrade'

# ==============================================================================
# Gerenciamento Imutável (Bootc e RPM-Ostree)
# ==============================================================================
alias status-ostree='rpm-ostree status'
alias status-bootc='bootc status'
alias rollback-ostree='sudo rpm-ostree rollback'
alias rollback-bootc='sudo bootc rollback'
alias rollback='sudo bootc rollback 2>/dev/null || sudo rpm-ostree rollback'

alias kargs='rpm-ostree kargs'
alias kargs-edit='sudo rpm-ostree kargs --editor'
alias config-diff='sudo ostree admin config-diff'

# ==============================================================================
# Status de Serviços e Timers do Sistema
# ==============================================================================
alias status-fw='sudo systemctl status firewalld'
alias status-dns='sudo systemctl status systemd-resolved'
# Suporte tanto ao libvirt modular (Fedora 39+) quanto ao tradicional
alias status-kvm='systemctl status virtqemud 2>/dev/null || systemctl status libvirtd'

alias status-podman='systemctl --user status podman-user-prune.timer'
alias status-flatpak-system='systemctl status flatpak-system-update.timer'
alias status-flatpak-user='systemctl --user status flatpak-user-update.timer'
alias status-rpm-ostree='systemctl status rpm-ostreed-automatic.timer'

# ==============================================================================
# Manutenção e Otimizações (BTRFS / Tmpfiles)
# ==============================================================================
alias tmpfiles-system='sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf'
alias tmpfiles-user='systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf'
alias tmpfiles-all='tmpfiles-system && tmpfiles-user'

# ==============================================================================
# Containers e Virtualização (Podman & Distrobox)
# ==============================================================================
alias podman-ps='podman ps -a'
alias podman-cleanup='podman system prune -af && podman volume prune -f'
alias distrobox-list='distrobox list'
