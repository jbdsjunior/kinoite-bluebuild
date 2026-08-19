#!/bin/sh
# =============================================================================
# kinoite-aliases.sh
# Kinoite BlueBuild - Aliases e Funções para Produtividade
# =============================================================================
# Este arquivo é SOURCED pelo /etc/profile (login shells).
# Define aliases condicionais: só ativa se o binário existir.
# =============================================================================

# --- GUARDA: Shell não-interativo? Sai imediatamente. ---
case "$-" in
    *i*) ;;  # Shell interativo: continua
    *)   return 0 2>/dev/null || exit 0 ;;
esac

# =============================================================================
# SUDO COM ALIASES
# =============================================================================
# Função sudo que expande aliases (permite 'sudo ll', 'sudo la', etc)
sudo() {
    if [ "$1" = "-i" ] || [ "$1" = "-s" ]; then
        command sudo "$@"
    else
        command sudo env EDITOR="$EDITOR" VISUAL="$VISUAL" "$@"
    fi
}

# =============================================================================
# NAVEGAÇÃO E LISTAGEM (Modernos)
# =============================================================================

# Navegação rápida
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ..2='cd ../..'
alias ..3='cd ../../..'
alias ..4='cd ../../../..'

# Criar diretórios com pais
alias mkdir='mkdir -pv'

# Listagem com cores (fallback para ls se eza não existir)
if command -v eza >/dev/null 2>&1; then
    # eza: ls moderno com ícones, git status, cores
    alias ls='eza --icons --color=always --group-directories-first'
    alias ll='eza -l --icons --color=always --group-directories-first --git'
    alias la='eza -la --icons --color=always --group-directories-first --git'
    alias lt='eza --tree --icons --color=always --level=2'
    alias lt3='eza --tree --icons --color=always --level=3'
else
    # Fallback para ls tradicional
    alias ls='ls --color=auto --group-directories-first'
    alias ll='ls -l --color=auto --group-directories-first'
    alias la='ls -la --color=auto --group-directories-first'
fi

# =============================================================================
# VISUALIZAÇÃO DE ARQUIVOS (Modernos)
# =============================================================================

# cat com syntax highlighting (fallback para cat se bat não existir)
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
    alias catp='bat'  # cat com paginação
else
    alias cat='cat'
fi

# grep com cores e contexto
if command -v rg >/dev/null 2>&1; then
    # ripgrep: grep moderno, rápido, respeita .gitignore
    alias grep='rg --color=always'
    alias grepi='rg -i --color=always'  # case-insensitive
    alias grepv='rg -v --color=always'  # invert match
else
    alias grep='grep --color=auto'
    alias grepi='grep -i --color=auto'
    alias grepv='grep -v --color=auto'
fi

# find moderno (fallback para find se fd não existir)
if command -v fd >/dev/null 2>&1; then
    alias find='fd'
    alias findh='fd --hidden'  # inclui arquivos ocultos
else
    alias find='find'
    alias findh='find . -name ".*" -prune -o -print'
fi

# =============================================================================
# PROTEÇÃO E SEGURANÇA
# =============================================================================

# Aliases seguros (não usam -i, mas previnem erros comuns)
alias rm='rm -v'           # verbose (mostra o que está removendo)
alias rmf='rm -f'          # force (sem verbose)
alias rmrf='rm -rf'        # recursive force (use com cuidado!)
alias cp='cp -v'           # verbose
alias cpf='cp -f'          # force
alias mv='mv -v'           # verbose
alias mvf='mv -f'          # force

# Prevenção de erros comuns
alias rm='rm -I'           # pergunta uma vez se >3 arquivos ou recursivo
alias cp='cp -i'           # pergunta antes de sobrescrever
alias mv='mv -i'           # pergunta antes de sobrescrever

# =============================================================================
# GIT (Básico)
# =============================================================================

alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'
alias glog='git log --oneline --graph --decorate'
alias gd='git diff'
alias gds='git diff --staged'
alias gb='git branch'
alias gco='git checkout'
alias gsw='git switch'

# Git com lazygit (se instalado)
if command -v lazygit >/dev/null 2>&1; then
    alias lg='lazygit'
fi

# =============================================================================
# SISTEMA E SERVIÇOS
# =============================================================================

# systemctl system
alias scs='sudo systemctl'
alias scs-start='sudo systemctl start'
alias scs-stop='sudo systemctl stop'
alias scs-restart='sudo systemctl restart'
alias scs-status='sudo systemctl status'
alias scs-enable='sudo systemctl enable'
alias scs-disable='sudo systemctl disable'
alias scs-list='sudo systemctl list-units --type=service'

# systemctl user
alias scu='systemctl --user'
alias scu-start='systemctl --user start'
alias scu-stop='systemctl --user stop'
alias scu-restart='systemctl --user restart'
alias scu-status='systemctl --user status'
alias scu-enable='systemctl --user enable'
alias scu-disable='systemctl --user disable'
alias scu-list='systemctl --user list-units --type=service'

# journalctl
alias j='journalctl'
alias j-f='journalctl -f'              # follow
alias j-u='journalctl -u'              # unit
alias j-user='journalctl --user'       # user journal
alias j-user-f='journalctl --user -f'  # follow user journal
alias j-today='journalctl --since today'
alias j-boot='journalctl -b'           # current boot
alias j-boot-prev='journalctl -b -1'   # previous boot

# =============================================================================
# ATUALIZAÇÕES E MANUTENÇÃO
# =============================================================================

# rpm-ostree
alias ostree-status='rpm-ostree status'
alias ostree-upgrade='sudo rpm-ostree upgrade'
alias ostree-rollback='sudo rpm-ostree rollback'
alias ostree-cleanup='sudo rpm-ostree cleanup -m'
alias ostree-diff='sudo ostree admin config-diff'

# bootc
alias bootc-status='bootc status'
alias bootc-upgrade='sudo bootc upgrade'
alias bootc-rollback='sudo bootc rollback'

# Flatpak
alias fp='flatpak'
alias fp-list='flatpak list'
alias fp-update='flatpak update'
alias fp-install='flatpak install'
alias fp-uninstall='flatpak uninstall'
alias fp-run='flatpak run'
alias fp-info='flatpak info'
alias fp-search='flatpak search'

# Flatpak system
alias fp-system-update='sudo flatpak update --system'
alias fp-system-list='flatpak list --system'

# Flatpak user
alias fp-user-update='flatpak update --user'
alias fp-user-list='flatpak list --user'

# Topgrade (se instalado)
if command -v topgrade >/dev/null 2>&1; then
    alias update='topgrade -cy --no-ask-retry --auto-retry 2 --only system flatpak'
    alias update-all='topgrade -cy --no-ask-retry --auto-retry 2'
    alias update-system='topgrade -cy --no-ask-retry --auto-retry 2 --only system'
    alias update-flatpak='topgrade -cy --no-ask-retry --auto-retry 2 --only flatpak'
else
    alias update='sudo rpm-ostree upgrade && flatpak update'
    alias update-system='sudo rpm-ostree upgrade'
    alias update-flatpak='flatpak update'
fi

# =============================================================================
# PODMAN E CONTAINERS
# =============================================================================

alias p='podman'
alias ps='podman ps'
alias psa='podman ps -a'
alias pi='podman images'
alias pr='podman run'
alias pe='podman exec -it'
alias pl='podman logs'
alias plf='podman logs -f'
alias prm='podman rm'
alias prmi='podman rmi'
alias pstop='podman stop'
alias pstart='podman start'
alias prestart='podman restart'

# Podman cleanup
alias podman-cleanup='podman system prune -af && podman volume prune -f'
alias podman-cleanup-all='podman system prune -af && podman volume prune -f && podman image prune -af'

# Podman Compose (se instalado)
if command -v podman-compose >/dev/null 2>&1; then
    alias pc='podman-compose'
    alias pc-up='podman-compose up -d'
    alias pc-down='podman-compose down'
    alias pc-logs='podman-compose logs -f'
    alias pc-restart='podman-compose restart'
fi

# =============================================================================
# DISTROBOX
# =============================================================================

if command -v distrobox >/dev/null 2>&1; then
    alias db='distrobox'
    alias db-list='distrobox list'
    alias db-enter='distrobox enter'
    alias db-create='distrobox create'
    alias db-delete='distrobox rm'
    alias db-stop='distrobox stop'
    alias db-start='distrobox start'
    alias db-exec='distrobox enter --'
fi

# =============================================================================
# RCLONE (Cloud Storage)
# =============================================================================

if command -v rclone >/dev/null 2>&1; then
    alias rc='rclone'
    alias rc-ls='rclone ls'
    alias rc-copy='rclone copy'
    alias rc-sync='rclone sync'
    alias rc-mount='rclone mount'
    alias rc-config='rclone config'
    alias rc-about='rclone about'
    alias rc-cleanup='rclone cleanup'
    alias rc-dedupe='rclone dedupe'
fi

# =============================================================================
# MONITORAMENTO E RECURSOS
# =============================================================================

# Processos
alias ps='ps auxf'
alias psa='ps auxf | less -R'
alias pstree='pstree -p'

# Monitoramento (usa btop se disponível, senão htop)
if command -v btop >/dev/null 2>&1; then
    alias top='btop'
    alias htop='btop'
elif command -v htop >/dev/null 2>&1; then
    alias top='htop'
fi

# I/O e rede
alias iotop='sudo iotop'
alias iftop='sudo iftop'
alias nethogs='sudo nethogs'
alias powertop='sudo powertop'

# Memória e disco
alias mem='free -h'
alias memw='watch -n 1 free -h'
alias df='df -h'
alias dfi='df -i'
alias du='du -sh'
alias duh='du -h --max-depth=1'
alias dusort='du -h --max-depth=1 | sort -hr'

# =============================================================================
# REDE
# =============================================================================

alias ping='ping -c 5'
alias ping6='ping6 -c 5'
alias ports='ss -tulnp'
alias ports-listen='ss -tlnp'
alias ip='ip -c'
alias ipa='ip -c addr'
alias ipl='ip -c link'
alias ipr='ip -c route'

# wget e curl
alias wget='wget -c'  # continue downloads
alias curl='curl -L'  # follow redirects
alias curlh='curl -I' # headers only

# =============================================================================
# KARGS E KERNEL
# =============================================================================

alias kargs='rpm-ostree kargs'
alias kargs-edit='EDITOR="${EDITOR:-nano}" sudo rpm-ostree kargs --editor'

# =============================================================================
# FIREWALL
# =============================================================================

alias fw='sudo firewall-cmd'
alias fw-status='sudo firewall-cmd --state'
alias fw-list='sudo firewall-cmd --list-all'
alias fw-reload='sudo firewall-cmd --reload'

# =============================================================================
# UTILITÁRIOS
# =============================================================================

# Recarregar perfil (seguro: valida sintaxe antes)
alias reload-profile='bash -n ~/.bashrc && source ~/.bashrc || echo "❌ Erro de sintaxe em ~/.bashrc"'
alias reload-bashrc='reload-profile'

# Histórico
alias h='history'
alias hg='history | grep'
alias hc='history -c'

# Aliases para editar configs rapidamente
alias edit-bashrc='nano ~/.bashrc'
alias edit-aliases='nano ~/.bash_aliases 2>/dev/null || echo "Arquivo não existe"'
alias edit-starship='nano ~/.config/starship/starship.toml'

# Extrair arquivos (detecta tipo automaticamente)
extract() {
    if [ -z "$1" ]; then
        echo "Uso: extract <arquivo>"
        return 1
    fi
    if [ ! -f "$1" ]; then
        echo "Arquivo não existe: $1"
        return 1
    fi
    case "$1" in
        *.tar.bz2)   tar xjf "$1"    ;;
        *.tar.gz)    tar xzf "$1"    ;;
        *.tar.xz)    tar xJf "$1"    ;;
        *.bz2)       bunzip2 "$1"    ;;
        *.rar)       unrar x "$1"    ;;
        *.gz)        gunzip "$1"     ;;
        *.tar)       tar xf "$1"     ;;
        *.tbz2)      tar xjf "$1"    ;;
        *.tgz)       tar xzf "$1"    ;;
        *.zip)       unzip "$1"      ;;
        *.Z)         uncompress "$1" ;;
        *.7z)        7z x "$1"       ;;
        *)           echo "Não sei extrair '$1'" ;;
    esac
}

# =============================================================================
# BTRFS NoCOW TMPFILES
# =============================================================================

alias tmpfiles-system='sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf'
alias tmpfiles-user='systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf'
alias tmpfiles-all='tmpfiles-system && tmpfiles-user'

# =============================================================================
# FIM
# =============================================================================