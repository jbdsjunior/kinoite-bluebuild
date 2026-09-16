#!/usr/bin/env bash
# ==============================================================================
# kinoite-setup-push-update
# Assistente de configuração e pós-instalação para atualizações Push via Tailscale
# ==============================================================================
set -euo pipefail

# Cores para terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SECRET_FILE="/etc/kinoite-update.secret"
PORT="58080"

# 1. Verificação de privilégios de root
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}[!] Este assistente requer privilégios de administrador (root).${NC}"
    echo -e "${BLUE}[*] Elevando com sudo...${NC}"
    exec sudo "$0" "$@"
fi

echo -e "${BOLD}${CYAN}"
echo "=============================================================================="
echo "          ASSISTENTE DE CONFIGURAÇÃO: ATUALIZAÇÕES PUSH (TAILSCALE)          "
echo "=============================================================================="
echo -e "${NC}"

# 2. Gerenciamento do segredo criptográfico HMAC-SHA256
echo -e "${BOLD}1. Verificação da Chave Secreta Local (/etc/kinoite-update.secret):${NC}"
if [[ -f "$SECRET_FILE" && -s "$SECRET_FILE" ]]; then
    SECRET=$(cat "$SECRET_FILE" | tr -d ' \n\r')
    echo -e "   ${GREEN}[✓] Chave secreta existente encontrada.${NC}"
    chmod 0400 "$SECRET_FILE"
    chown root:root "$SECRET_FILE"
else
    echo -e "   ${BLUE}[*] Gerando nova chave secreta criptográfica (256-bit)...${NC}"
    SECRET=$(openssl rand -hex 32)
    echo -n "$SECRET" > "$SECRET_FILE"
    chmod 0400 "$SECRET_FILE"
    chown root:root "$SECRET_FILE"
    echo -e "   ${GREEN}[✓] Chave gerada com sucesso em $SECRET_FILE (modo 0400).${NC}"
fi

# 3. Detecção da conectividade e endereço Tailscale
echo ""
echo -e "${BOLD}2. Verificação de Rede e Tailscale:${NC}"
TS_IP=""
TS_HOSTNAME=""

if command -v tailscale &>/dev/null; then
    if tailscale status &>/dev/null; then
        TS_IP=$(tailscale ip -4 2>/dev/null || true)
        TS_HOSTNAME=$(tailscale status --json 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin).get('Self', {}).get('DNSName', '').rstrip('.'))" 2>/dev/null || true)
        echo -e "   ${GREEN}[✓] Tailscale conectado e ativo!${NC}"
        echo -e "       IP Tailscale:   ${CYAN}${TS_IP:-Não detectado}${NC}"
        echo -e "       MagicDNS:       ${CYAN}${TS_HOSTNAME:-Não detectado}${NC}"
    else
        echo -e "   ${YELLOW}[!] Tailscale está instalado, mas NÃO está conectado.${NC}"
        echo -e "       Execute: ${BOLD}sudo tailscale up${NC} para autenticar seu dispositivo na tailnet."
    fi
else
    echo -e "   ${YELLOW}[!] Binário 'tailscale' não encontrado no PATH.${NC}"
fi

if [[ -n "$TS_IP" ]]; then
    RECEIVER_URL="http://${TS_IP}:${PORT}"
elif [[ -n "$TS_HOSTNAME" ]]; then
    RECEIVER_URL="http://${TS_HOSTNAME}:${PORT}"
else
    RECEIVER_URL="http://<SEU-IP-TAILSCALE>:${PORT}"
fi

# 4. Verificação / Ativação do Socket Systemd
echo ""
echo -e "${BOLD}3. Status do Socket Systemd (Porta ${PORT}):${NC}"
SOCKET_ACTIVE=false

if systemctl list-unit-files kinoite-update-trigger.socket &>/dev/null; then
    systemctl daemon-reload
    systemctl enable --now kinoite-update-trigger.socket &>/dev/null
    if systemctl is-active kinoite-update-trigger.socket &>/dev/null; then
        echo -e "   ${GREEN}[✓] kinoite-update-trigger.socket está HABILITADO e ATIVO.${NC}"
        echo -e "       Em repouso: 0 MB de RAM e 0% CPU (socket sob custódia do PID 1)."
        SOCKET_ACTIVE=true
    else
        echo -e "   ${RED}[✗] Falha ao ativar kinoite-update-trigger.socket.${NC}"
    fi
else
    # Se o script estiver sendo executado direto do repo clonado antes de rebasear a imagem
    SCRIPT_PATH="$(readlink -f "$0")"
    REPO_DIR="$(cd "$(dirname "$SCRIPT_PATH")/../../.." 2>/dev/null && pwd || true)"
    if [[ -f "$REPO_DIR/files/system/usr/lib/systemd/system/kinoite-update-trigger.socket" ]]; then
        echo -e "   ${BLUE}[*] Instalando unidades no sistema a partir do repositório local...${NC}"
        install -m 0755 "$REPO_DIR/files/system/usr/libexec/kinoite-update-receiver" /usr/libexec/kinoite-update-receiver
        cp "$REPO_DIR/files/system/usr/lib/systemd/system/kinoite-update-trigger.socket" /etc/systemd/system/
        cp "$REPO_DIR/files/system/usr/lib/systemd/system/kinoite-update-trigger@.service" /etc/systemd/system/
        systemctl daemon-reload
        systemctl enable --now kinoite-update-trigger.socket &>/dev/null
        echo -e "   ${GREEN}[✓] Unidades instaladas e socket ativado com sucesso!${NC}"
        SOCKET_ACTIVE=true
    else
        echo -e "   ${YELLOW}[i] kinoite-update-trigger.socket ainda não está instalado no SO.${NC}"
        echo -e "       Ele será ativado automaticamente após o próximo bootc upgrade da nova imagem."
    fi
fi

# 5. Informações sobre coexistência com método antigo (Fallback)
echo ""
echo -e "${BOLD}4. Política de Atualização Antiga vs Nova (Coexistência Segura):${NC}"
if systemctl is-enabled bootc-fetch-apply-updates.timer &>/dev/null; then
    echo -e "   ${GREEN}[✓] O timer tradicional ('bootc-fetch-apply-updates.timer') continua ATIVO.${NC}"
    echo -e "   ${BLUE}[i] Garantia de redundância:${NC} Ambas as soluções funcionam em paralelo."
    echo -e "       - Push: Atualização instantânea sempre que a imagem for compilada."
    echo -e "       - Timer: Verificação periódica (a cada 45m) como fallback seguro."
    echo -e "       Quando você confirmar que o Push está 100% funcional, você poderá desativar o timer com:"
    echo -e "       ${YELLOW}sudo systemctl disable --now bootc-fetch-apply-updates.timer${NC}"
else
    echo -e "   ${YELLOW}[i] O timer 'bootc-fetch-apply-updates.timer' está inativo ou não instalado.${NC}"
fi

# 6. Teste local de disparo HMAC (Loopback)
if [[ "$SOCKET_ACTIVE" = true ]]; then
    echo ""
    echo -e "${BOLD}5. Teste de Validação Local:${NC}"
    TIMESTAMP=$(date +%s)
    PAYLOAD="{\"timestamp\": $TIMESTAMP, \"test\": true, \"source\": \"kinoite-setup-push-update\"}"
    SIG=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | cut -d' ' -f2)

    TEST_RES=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://127.0.0.1:${PORT}" \
        -H "Content-Type: application/json" \
        -H "X-Signature: $SIG" \
        -H "X-Timestamp: $TIMESTAMP" \
        -d "$PAYLOAD" || echo "000")

    if [[ "$TEST_RES" == "200" ]]; then
        echo -e "   ${GREEN}[✓] Teste de autenticação local bem-sucedido (HTTP 200 OK)!${NC}"
        echo -e "       O receptor validou a assinatura HMAC e respondeu corretamente."
    else
        echo -e "   ${YELLOW}[!] Teste retornou status HTTP ${TEST_RES}.${NC}"
        echo -e "       Consulte os logs com: journalctl -u 'kinoite-update-trigger@*' -e"
    fi
fi

# 7. Resumo formatado para copiar e colar no GitHub
echo ""
echo -e "${BOLD}${CYAN}==============================================================================${NC}"
echo -e "${BOLD}          COPIE E COLE ESTES SECRETS NO GITHUB ACTIONS:                       ${NC}"
echo -e "${BOLD}${CYAN}==============================================================================${NC}"
echo -e "No seu repositório GitHub:"
echo -e "👉 ${BOLD}Settings > Secrets and variables > Actions > New repository secret${NC}"
echo ""
echo -e "${BOLD}1) UPDATE_HMAC_SECRET${NC}"
echo -e "${GREEN}${SECRET}${NC}"
echo ""
echo -e "${BOLD}2) UPDATE_RECEIVER_URL${NC}"
echo -e "${GREEN}${RECEIVER_URL}${NC}"
echo ""
echo -e "${BOLD}3) TAILSCALE_AUTHKEY${NC}"
echo -e "Gere no console da Tailscale (${CYAN}https://login.tailscale.com/admin/settings/keys${CYAN}${NC}):"
echo -e "   - Reusable:       ${BOLD}ON${NC}"
echo -e "   - Ephemeral:      ${BOLD}ON${NC} (garante que os runners do GitHub sejam removidos após o job)"
echo -e "   - Pre-authorized: ${BOLD}ON${NC}"
echo -e "   - Tags:           ${BOLD}tag:ci${NC}"
echo -e "${BOLD}${CYAN}==============================================================================${NC}"
echo ""
