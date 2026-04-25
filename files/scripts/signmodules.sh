#!/usr/bin/env bash
set -oue pipefail

MODULE_NAME="${1-}"
if [ -z "$MODULE_NAME" ]; then
  echo "MODULE_NAME is empty. Exiting..."
  exit 1
fi

KERNEL_VERSION="$(rpm -q "kernel" --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

PUBLIC_KEY_DER_PATH="${PUBLIC_KEY_DER_PATH:-/etc/pki/akmods/certs/public_key.der}"
PRIVATE_KEY_PATH="/tmp/certs/private_key.priv"

TMP_GEN_DIR="/var/tmp/certs_gen"
mkdir -p "$TMP_GEN_DIR"
PUBLIC_KEY_CRT_PATH="${TMP_GEN_DIR}/public_key.crt"
SIGNING_KEY="${TMP_GEN_DIR}/signing_key.pem"

if [ ! -f "$PRIVATE_KEY_PATH" ]; then
    echo "Erro Crítico: Chave Privada MOK não encontrada em ${PRIVATE_KEY_PATH}."
    exit 1
fi

if [ ! -f "$PUBLIC_KEY_DER_PATH" ]; then
    echo "Erro Crítico: Chave Pública DER não encontrada em ${PUBLIC_KEY_DER_PATH}."
    exit 1
fi

openssl x509 -inform DER -in "$PUBLIC_KEY_DER_PATH" -out "$PUBLIC_KEY_CRT_PATH"
cat "$PRIVATE_KEY_PATH" <(echo) "$PUBLIC_KEY_CRT_PATH" >> "$SIGNING_KEY"

for module in /usr/lib/modules/"${KERNEL_VERSION}"/extra/"${MODULE_NAME}"/*.ko*; do
  module_suffix="${module##*.}"

  if [[ "$module_suffix" == "xz" ]]; then
    module_basename="${module:0:-3}"
    xz --decompress "$module"
    openssl cms -sign -signer "${SIGNING_KEY}" -binary -in "$module_basename" -outform DER -out "${module_basename}.cms" -nocerts -noattr -nosmimecap
    /usr/src/kernels/"${KERNEL_VERSION}"/scripts/sign-file -s "${module_basename}.cms" sha256 "${PUBLIC_KEY_CRT_PATH}" "${module_basename}"
    bash "$SCRIPT_DIR/sign-check.sh" "${KERNEL_VERSION}" "${module_basename}" "${PUBLIC_KEY_CRT_PATH}"
    xz -C crc32 -f "${module_basename}"

  elif [[ "$module_suffix" == "gz" ]]; then
    module_basename="${module:0:-3}"
    gzip -d "$module"
    openssl cms -sign -signer "${SIGNING_KEY}" -binary -in "$module_basename" -outform DER -out "${module_basename}.cms" -nocerts -noattr -nosmimecap
    /usr/src/kernels/"${KERNEL_VERSION}"/scripts/sign-file -s "${module_basename}.cms" sha256 "${PUBLIC_KEY_CRT_PATH}" "${module_basename}"
    bash "$SCRIPT_DIR/sign-check.sh" "${KERNEL_VERSION}" "${module_basename}" "${PUBLIC_KEY_CRT_PATH}"
    gzip -9f "${module_basename}"

  # ATUALIZADO: Suporte nativo ao ZSTD do Fedora Kinoite 40/41+
  elif [[ "$module_suffix" == "zst" ]]; then
    module_basename="${module:0:-4}"
    zstd -d --rm "$module"
    openssl cms -sign -signer "${SIGNING_KEY}" -binary -in "$module_basename" -outform DER -out "${module_basename}.cms" -nocerts -noattr -nosmimecap
    /usr/src/kernels/"${KERNEL_VERSION}"/scripts/sign-file -s "${module_basename}.cms" sha256 "${PUBLIC_KEY_CRT_PATH}" "${module_basename}"
    bash "$SCRIPT_DIR/sign-check.sh" "${KERNEL_VERSION}" "${module_basename}" "${PUBLIC_KEY_CRT_PATH}"
    zstd -19 --rm "${module_basename}"

  else
    openssl cms -sign -signer "${SIGNING_KEY}" -binary -in "$module" -outform DER -out "${module}.cms" -nocerts -noattr -nosmimecap
    /usr/src/kernels/"${KERNEL_VERSION}"/scripts/sign-file -s "${module}.cms" sha256 "${PUBLIC_KEY_CRT_PATH}" "${module}"
    bash "$SCRIPT_DIR/sign-check.sh" "${KERNEL_VERSION}" "${module}" "${PUBLIC_KEY_CRT_PATH}"
  fi
done

rm -rf "$TMP_GEN_DIR"