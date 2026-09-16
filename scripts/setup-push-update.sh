#!/usr/bin/env bash
# ==============================================================================
# scripts/setup-push-update.sh
# Wrapper canônico para files/system/usr/bin/kinoite-setup-push-update
# Garante fonte única da verdade para o assistente de pós-instalação
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CANONICAL_TARGET="$SCRIPT_DIR/../files/system/usr/bin/kinoite-setup-push-update"

if [[ -f "$CANONICAL_TARGET" ]]; then
    exec "$CANONICAL_TARGET" "$@"
else
    echo "Erro: Assistente canônico não encontrado em $CANONICAL_TARGET" >&2
    exit 1
fi
