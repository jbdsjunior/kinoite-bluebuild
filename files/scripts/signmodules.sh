#!/usr/bin/env bash
set -oue pipefail

MODULE_NAME="${1-}"
if [ -z "$MODULE_NAME" ]; then
  echo "MODULE_NAME is empty. Exiting..."
  exit 1
fi

KERNEL_VERSION="$(rpm -q "kernel" --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Caminhos fixos onde o GitHub Actions injetará as chaves
CERT_DIR="/tmp/certs"
PUBLIC_KEY_DER_PATH="${CERT_DIR}/public_key.der"
PRIVATE_KEY_PATH="${CERT_DIR}/private_key.priv"
PUBLIC_KEY_CRT_PATH="${CERT_DIR}/public_key.crt"
SIGNING_KEY="${CERT_DIR}/signing_key.pem"

if [ ! -f "$PRIVATE_KEY_PATH" ] || [ ! -f "$PUBLIC_KEY_DER_PATH" ]; then
    echo "Erro Crítico: Chaves MOK não encontradas em ${CERT_DIR}."
    exit 1
fi

# Prepara os certificados
openssl x509 -inform DER -in "$PUBLIC_KEY_DER_PATH" -out "$PUBLIC_KEY_CRT_PATH"
cat "$PRIVATE_KEY_PATH" <(echo) "$PUBLIC_KEY_CRT_PATH" >> "$SIGNING_KEY"

# Varre e assina os módulos (.ko, .ko.xz, .ko.gz)
for module in /usr/lib/modules/"${KERNEL_VERSION}"/extra/"${MODULE_NAME}"/*.ko*; do
  module_basename="${module:0:-3}"
  module_suffix="${module: -3}"

  if [[ "$module_suffix" == ".xz" ]]; then
    xz --decompress "$module"
    openssl cms -sign -signer "${SIGNING_KEY}" -binary -in "$module_basename" -outform DER -out "${module_basename}.cms" -nocerts -noattr -nosmimecap
    /usr/src/kernels/"${KERNEL_VERSION}"/scripts/sign-file -s "${module_basename}.cms" sha256 "${PUBLIC_KEY_CRT_PATH}" "${module_basename}"
    bash "$SCRIPT_DIR/sign-check.sh" "${KERNEL_VERSION}" "${module_basename}" "${PUBLIC_KEY_CRT_PATH}"
    xz -C crc32 -f "${module_basename}"
  elif [[ "$module_suffix" == ".gz" ]]; then
    gzip -d "$module"
    openssl cms -sign -signer "${SIGNING_KEY}" -binary -in "$module_basename" -outform DER -out "${module_basename}.cms" -nocerts -noattr -nosmimecap
    /usr/src/kernels/"${KERNEL_VERSION}"/scripts/sign-file -s "${module_basename}.cms" sha256 "${PUBLIC_KEY_CRT_PATH}" "${module_basename}"
    bash "$SCRIPT_DIR/sign-check.sh" "${KERNEL_VERSION}" "${module_basename}" "${PUBLIC_KEY_CRT_PATH}"
    gzip -9f "${module_basename}"
  else
    openssl cms -sign -signer "${SIGNING_KEY}" -binary -in "$module" -outform DER -out "${module}.cms" -nocerts -noattr -nosmimecap
    /usr/src/kernels/"${KERNEL_VERSION}"/scripts/sign-file -s "${module}.cms" sha256 "${PUBLIC_KEY_CRT_PATH}" "${module}"
    bash "$SCRIPT_DIR/sign-check.sh" "${KERNEL_VERSION}" "${module}" "${PUBLIC_KEY_CRT_PATH}"
  fi
done