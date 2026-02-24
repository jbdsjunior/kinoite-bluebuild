#!/usr/bin/env bash

set -u

JOURNAL_DAYS="${JOURNAL_DAYS:-14}"
DO_FLATPAK_REPAIR=false
DO_CLEAN_DEPLOYMENTS=false
DO_PODMAN_PRUNE=false
DRY_RUN=false

usage() {
  cat <<'EOF'
Uso: mantence.sh [opcoes]

Manutencao geral para Fedora Kinoite/Bluebuild:
- Atualiza e limpa metadata do rpm-ostree
- Atualiza Flatpaks (usuario e sistema)
- Remove Flatpaks nao usados
- Limpa logs antigos do systemd-journal
- Executa limpeza de arquivos temporarios do sistema

Opcoes:
  --repair-flatpak        Executa flatpak repair (usuario e sistema)
  --clean-deployments     Remove deployment pendente e rollback do rpm-ostree
  --prune-podman          Executa podman system prune -af
  --journal-days N        Dias de retencao do journal (padrao: 14)
  -n, --dry-run           Mostra comandos sem executar
  -h, --help              Exibe esta ajuda
EOF
}

log() {
  printf '\n[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

warn() {
  printf '[aviso] %s\n' "$*" >&2
}

die() {
  printf '[erro] %s\n' "$*" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

print_cmd() {
  printf '%q ' "$@"
  printf '\n'
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] '
    print_cmd "$@"
    return 0
  fi
  "$@"
}

run_root() {
  if [[ "$EUID" -eq 0 ]]; then
    run "$@"
    return
  fi

  if ! command_exists sudo; then
    die "sudo nao encontrado; execute como root ou instale sudo."
  fi

  run sudo "$@"
}

run_step() {
  local description="$1"
  shift
  log "$description"
  if ! "$@"; then
    warn "Falha nessa etapa (continuando): $description"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repair-flatpak)
      DO_FLATPAK_REPAIR=true
      ;;
    --clean-deployments)
      DO_CLEAN_DEPLOYMENTS=true
      ;;
    --prune-podman)
      DO_PODMAN_PRUNE=true
      ;;
    --journal-days)
      shift
      [[ $# -gt 0 ]] || die "Informe um valor inteiro para --journal-days."
      [[ "$1" =~ ^[0-9]+$ ]] || die "Valor invalido para --journal-days: $1"
      JOURNAL_DAYS="$1"
      ;;
    -n|--dry-run)
      DRY_RUN=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Opcao desconhecida: $1"
      ;;
  esac
  shift
done

if command_exists rpm-ostree; then
  run_step "rpm-ostree: atualizando deployment" run_root rpm-ostree upgrade
  run_step "rpm-ostree: limpando metadata/cache de pacotes" run_root rpm-ostree cleanup -m

  if [[ "$DO_CLEAN_DEPLOYMENTS" == true ]]; then
    run_step "rpm-ostree: removendo deployment pendente" run_root rpm-ostree cleanup -p
    run_step "rpm-ostree: removendo rollback" run_root rpm-ostree cleanup -r
  fi
else
  warn "rpm-ostree nao encontrado; etapa de sistema imutavel ignorada."
fi

if command_exists flatpak; then
  run_step "Flatpak (usuario): atualizando apps/runtimes" run flatpak update --user -y
  run_step "Flatpak (sistema): atualizando apps/runtimes" run_root flatpak update --system -y
  run_step "Flatpak (usuario): removendo itens nao usados" run flatpak uninstall --user --unused -y
  run_step "Flatpak (sistema): removendo itens nao usados" run_root flatpak uninstall --system --unused -y

  if [[ "$DO_FLATPAK_REPAIR" == true ]]; then
    run_step "Flatpak (usuario): reparando instalacao" run flatpak repair --user
    run_step "Flatpak (sistema): reparando instalacao" run_root flatpak repair --system
  fi
else
  warn "flatpak nao encontrado; etapa Flatpak ignorada."
fi

if command_exists journalctl; then
  run_step "Journal: rotacionando logs" run_root journalctl --rotate
  run_step "Journal: removendo logs com mais de ${JOURNAL_DAYS} dias" \
    run_root journalctl --vacuum-time="${JOURNAL_DAYS}d"
else
  warn "journalctl nao encontrado; limpeza de logs ignorada."
fi

if command_exists systemd-tmpfiles; then
  run_step "systemd-tmpfiles: limpeza de temporarios" run_root systemd-tmpfiles --clean
else
  warn "systemd-tmpfiles nao encontrado; limpeza de temporarios ignorada."
fi

if [[ "$DO_PODMAN_PRUNE" == true ]]; then
  if command_exists podman; then
    run_step "Podman: limpando imagens/containers nao usados" run podman system prune -af
  else
    warn "podman nao encontrado; prune ignorado."
  fi
fi

if command_exists rpm-ostree; then
  run_step "Status atual do rpm-ostree" run rpm-ostree status
  printf '\nReinicie o sistema se houver deployment pendente para aplicar atualizacoes.\n'
fi

log "Manutencao finalizada."
