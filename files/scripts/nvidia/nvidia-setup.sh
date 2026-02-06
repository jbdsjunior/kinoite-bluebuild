#!/bin/bash
set -euo pipefail

# Caminho da chave pública que persistimos durante o build
KEY_PATH="/usr/share/distribution-gpg-keys/kinoite-custom/nvidia-modsign.der"

echo "=== Configuração de Secure Boot para NVIDIA (RPM Fusion) ==="

if [ ! -f "$KEY_PATH" ]; then
    echo "❌ Erro: Chave pública não encontrada."
    echo "   Verifique se o build no GitHub recebeu as secrets NVIDIA_SIGNING_KEY/CERT."
    exit 1
fi

# Verifica se o Secure Boot está ativo
SB_STATE="$(mokutil --sb-state || true)"
echo "Estado atual: $SB_STATE"
if ! echo "$SB_STATE" | grep -qi "enabled"; then
    echo "⚠️  Secure Boot parece desativado. A importação MOK não é necessária neste estado."
fi

echo ""
echo "Esta etapa irá agendar a importação da chave do driver NVIDIA no MOK (Machine Owner Key)."
echo "Você precisará definir uma SENHA TEMPORÁRIA agora."
echo "⚠️  Memorize esta senha! Ela será pedida na tela azul após o reinício."
echo ""

read -p "Pressione ENTER para continuar..."
sudo mokutil --import "$KEY_PATH"

echo ""
echo "✅ Sucesso! Chave agendada."
echo "Reinicie o computador e siga os passos na tela azul 'Enroll MOK'."
