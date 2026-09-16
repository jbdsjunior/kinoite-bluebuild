# ==============================================================================
# Justfile - Automação de Comandos para Kinoite BlueBuild
# Documentação: https://just.systems/man/en/
# ==============================================================================

set shell := ["bash", "-c"]

# Exibe a lista de receitas disponíveis
default:
    @just --list

# Executa validação de sintaxe em scripts shell e arquivos YAML
check:
    @echo "[*] Validando sintaxe de scripts shell..."
    @bash -n files/system/usr/bin/kinoite-setup-push-update
    @bash -n scripts/setup-push-update.sh
    @python3 -m py_compile files/system/usr/libexec/kinoite-update-receiver
    @echo "[✓] Scripts shell e Python validados com sucesso!"
    @if command -v yamllint >/dev/null 2>&1; then \
        echo "[*] Validando arquivos YAML com yamllint..."; \
        yamllint -d "{extends: relaxed, rules: {line-length: disable}}" recipes/ .github/workflows/; \
        echo "[✓] Arquivos YAML validados com sucesso!"; \
    fi

# Executa o assistente interativo de configuração Push via Tailscale
setup-push:
    sudo ./scripts/setup-push-update.sh

# Dispara uma requisição de teste local autenticada com HMAC para a porta 58080
test-push:
    @if [ ! -f /etc/kinoite-update.secret ]; then \
        echo "[!] Arquivo /etc/kinoite-update.secret não encontrado. Execute 'just setup-push' primeiro."; \
        exit 1; \
    fi
    @SECRET=$$(sudo cat /etc/kinoite-update.secret); \
    TIMESTAMP=$$(date +%s); \
    PAYLOAD="{\"timestamp\": $$TIMESTAMP, \"test\": true, \"source\": \"just-test-push\"}"; \
    SIG=$$(echo -n "$$PAYLOAD" | openssl dgst -sha256 -hmac "$$SECRET" | cut -d' ' -f2); \
    echo "[*] Enviando requisição autenticada de teste para http://127.0.0.1:58080..."; \
    curl -i -X POST http://127.0.0.1:58080 \
        -H "Content-Type: application/json" \
        -H "X-Signature: $$SIG" \
        -H "X-Timestamp: $$TIMESTAMP" \
        -d "$$PAYLOAD"

# Exibe o status consolidado de atualização, timers e sockets do sistema
status:
    @echo "=== STATUS DO BOOTC ==="
    @sudo bootc status 2>/dev/null || echo "bootc não disponível neste ambiente"
    @echo ""
    @echo "=== SOCKET PUSH (Porta 58080) ==="
    @systemctl status kinoite-update-trigger.socket --no-pager 2>/dev/null || true
    @echo ""
    @echo "=== TIMER DE POLLING (Fallback) ==="
    @systemctl status bootc-fetch-apply-updates.timer --no-pager 2>/dev/null || true
    @echo ""
    @echo "=== TIMERS DE FLATPAK & PODMAN ==="
    @systemctl status flatpak-system-update.timer podman-auto-update.timer --no-pager 2>/dev/null || true

# Acompanha logs do receptor de push em tempo real
logs-push:
    journalctl -u "kinoite-update-trigger@*" -f

