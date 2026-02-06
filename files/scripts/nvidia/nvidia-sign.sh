#!/bin/bash
set -euo pipefail

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
printf "%s\n" "$NVIDIA_SIGNING_KEY" > "$PRIVATE_KEY_PATH"

# Aceita certificado em PEM (BEGIN CERTIFICATE) ou DER em base64.
if printf "%s" "$NVIDIA_SIGNING_CERT" | grep -q "BEGIN CERTIFICATE"; then
    tmp_pem="$(mktemp)"
    printf "%s\n" "$NVIDIA_SIGNING_CERT" > "$tmp_pem"
    openssl x509 -in "$tmp_pem" -outform DER -out "$PUBLIC_KEY_PATH"
    rm -f "$tmp_pem"
else
    if ! printf "%s" "$NVIDIA_SIGNING_CERT" | base64 -d > "$PUBLIC_KEY_PATH" 2>/dev/null; then
        printf "%s" "$NVIDIA_SIGNING_CERT" > "$PUBLIC_KEY_PATH"
    fi
fi

# Permissões restritas exigidas pelo akmods
chmod 600 "$PRIVATE_KEY_PATH"
chmod 644 "$PUBLIC_KEY_PATH"

if ! openssl x509 -inform DER -in "$PUBLIC_KEY_PATH" -noout >/dev/null 2>&1; then
    echo "❌ Erro: NVIDIA_SIGNING_CERT inválido (esperado PEM ou DER/base64 de certificado X.509)."
    exit 1
fi

# 2. Força a reconstrução dos módulos (akmods) usando as chaves injetadas
# Isso garante que o módulo .ko seja assinado antes de entrar na imagem.
mapfile -t KERNEL_VERSIONS < <(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -u)
if [[ "${#KERNEL_VERSIONS[@]}" -eq 0 ]]; then
    echo "❌ Erro: nenhum kernel-core encontrado para assinar módulos."
    exit 1
fi

for KERNEL_VERSION in "${KERNEL_VERSIONS[@]}"; do
    echo "Compilando e assinando módulos para o kernel $KERNEL_VERSION..."
    akmods --force --kernels "$KERNEL_VERSION" --kmod nvidia

    # Validação best-effort: confirma se o módulo reporta signer.
    if SIGNER="$(modinfo -k "$KERNEL_VERSION" -F signer nvidia 2>/dev/null)" && [[ -n "$SIGNER" ]]; then
        echo "Módulo nvidia assinado por: $SIGNER"
    else
        echo "⚠️  Aviso: não foi possível validar o signer do módulo nvidia para $KERNEL_VERSION."
    fi
done

# 3. Disponibiliza a chave pública para o setup pós-instalação
cp "$PUBLIC_KEY_PATH" "$USER_KEY_DIR/nvidia-modsign.der"

# 4. Limpeza de Segurança (Remove a chave privada da imagem final)
rm -f "$PRIVATE_KEY_PATH"

echo "=== Concluído: Driver NVIDIA assinado e chave pública pronta para importação. ==="
