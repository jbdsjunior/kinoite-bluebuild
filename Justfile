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
    @find files/ -type f -name "*.sh" -exec bash -n {} +
    @echo "[✓] Scripts shell validados com sucesso!"
    @if command -v yamllint >/dev/null 2>&1; then \
        echo "[*] Validando arquivos YAML com yamllint..."; \
        yamllint -d "{extends: relaxed, rules: {line-length: disable}}" recipes/ .github/workflows/; \
        echo "[✓] Arquivos YAML validados com sucesso!"; \
    fi

# Exibe o status consolidado de atualização, timers e serviços do sistema
status:
    @echo "=== STATUS DO BOOTC ==="
    @sudo bootc status 2>/dev/null || echo "bootc não disponível neste ambiente"
    @echo ""
    @echo "=== TIMERS DE ATUALIZAÇÃO DO SISTEMA ==="
    @systemctl status bootc-fetch-apply-updates.timer --no-pager 2>/dev/null || true
    @echo ""
    @echo "=== TIMERS DE FLATPAK & PODMAN ==="
    @systemctl status flatpak-system-update.timer podman-auto-update.timer --no-pager 2>/dev/null || true

# Executa atualização manual de bootc e flatpaks
update:
    sudo bootc update
    flatpak update -y
