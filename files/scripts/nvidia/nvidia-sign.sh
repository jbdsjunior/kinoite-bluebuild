#!/bin/bash
set -ouex pipefail

# Caminhos oficiais do RPM Fusion para chaves de assinatura
# Referência: https://rpmfusion.org/Howto/Secure%20Boot
AKMODS_CERT_DIR="/etc/pki/akmods/certs"
AKMODS_PRIV_DIR="/etc/pki/akmods/private"
PUBLIC_KEY_PATH="$AKMODS_CERT_DIR/public_key.der"
PRIVATE_KEY_PATH="$AKMODS_PRIV_DIR/private_key.priv"

# Diretório para persistir a chave pública para o usuário final
USER_KEY_DIR="/usr/share/distribution-gpg-keys/kinoite-custom"

echo "=== Configurando Assinatura NVIDIA (Padrão RPM Fusion) ==="

# Cria a estrutura de diretórios padrão do RPM Fusion
mkdir -p "$AKMODS_CERT_DIR" "$AKMODS_PRIV_DIR" "$USER_KEY_DIR"

# 1. Recupera as chaves das Variáveis de Ambiente (GitHub Secrets)
if [[ -z "${NVIDIA_SIGNING_KEY:-}" ]] || [[ -z "${NVIDIA_SIGNING_CERT:-}" ]]; then
    echo "⚠️  AVISO: Variáveis NVIDIA_SIGNING_KEY ou NVIDIA_SIGNING_CERT não encontradas."
    echo "   O driver NVIDIA será instalado SEM assinatura para Secure Boot."
    exit 0
fi

echo "Injetando chaves de assinatura..."
echo "$NVIDIA_SIGNING_KEY" > "$PRIVATE_KEY_PATH"
echo "$NVIDIA_SIGNING_CERT" > "$PUBLIC_KEY_PATH"

# Permissões restritas exigidas pelo akmods
chmod 600 "$PRIVATE_KEY_PATH"
chmod 644 "$PUBLIC_KEY_PATH"

# 2. Força a reconstrução dos módulos (akmods) usando as chaves injetadas
# Isso garante que o módulo .ko seja assinado antes de entrar na imagem.
KERNEL_VERSION=$(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')
echo "Compilando e assinando módulos para o kernel $KERNEL_VERSION..."

akmods --force --kernels "$KERNEL_VERSION" --kmod nvidia

# 3. Disponibiliza a chave pública para o setup pós-instalação
cp "$PUBLIC_KEY_PATH" "$USER_KEY_DIR/nvidia-modsign.der"

# 4. Limpeza de Segurança (Remove a chave privada da imagem final)
rm -f "$PRIVATE_KEY_PATH"

echo "=== Concluído: Driver NVIDIA assinado e chave pública pronta para importação. ==="