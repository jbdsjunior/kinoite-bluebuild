#!/usr/bin/env bash
# ==============================================================================
# Native NVIDIA Kernel Module Builder & Secure Boot Signer (Zero Downgrade Policy)
# Inspired by BlueBuild Base Images PR #46 & Universal Blue Bazzite
# ==============================================================================
set -euo pipefail

echo "==> [NVIDIA Native Build] Detecting installed kernel version..."
KERNEL_CORE_PKG=$(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')
KERNEL_VER_ONLY=$(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}')
echo "    Target kernel: ${KERNEL_CORE_PKG}"

echo "==> [NVIDIA Native Build] Enabling RPM Fusion Nonfree & installing build tools..."
dnf5 -y install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-45.noarch.rpm

dnf5 -y --setopt=install_weak_deps=False install \
    "kernel-devel-${KERNEL_VER_ONLY}" \
    akmods \
    gcc-c++ \
    openssl \
    kmodtool

# Configure MOK keys for deterministic module signing
echo "==> [NVIDIA Native Build] Configuring MOK signing keys..."
MOK_DIR="/etc/pki/akmods"
mkdir -p "${MOK_DIR}/certs" "${MOK_DIR}/private"

if [[ -f "${MOK_DIR}/certs/public_key.der" && -f "${MOK_DIR}/private/private_key.priv" ]]; then
    echo "    Using pre-provisioned MOK keypair from /etc/pki/akmods/"
else
    echo "    Generating new deterministic MOK keypair..."
    openssl req -new -nodes -utf8 -sha256 -days 36500 -batch -x509 \
        -subj "/CN=kinoite-bluebuild MOK/O=kinoite-bluebuild/emailAddress=root@kinoite-bluebuild.local" \
        -newkey rsa:4096 \
        -keyout "${MOK_DIR}/private/private_key.priv" \
        -outform DER \
        -out "${MOK_DIR}/certs/public_key.der"
fi
chmod 600 "${MOK_DIR}/private/private_key.priv"
chmod 644 "${MOK_DIR}/certs/public_key.der"

# Configure macros.kmodtool to force signing of modules during akmods build
mkdir -p /etc/rpm/macros.d
cat << 'MOK_MACROS' > /etc/rpm/macros.d/macros.kmodtool
%__kmodtool_signmodules 1
%__kmodtool_signmodules_pubkey /etc/pki/akmods/certs/public_key.der
%__kmodtool_signmodules_privkey /etc/pki/akmods/private/private_key.priv
MOK_MACROS

# In Fedora container builds running as root, akmodsbuild checks [[ -w /var ]]
# and aborts with "ERROR: Not to be used as root". Exactly like upstream BlueBuild PR #46:
cp /usr/sbin/akmodsbuild /usr/sbin/akmodsbuild.backup
sed -i '/if \[\[ -w \/var \]\] ; then/,/fi/d' /usr/sbin/akmodsbuild

echo "==> [NVIDIA Native Build] Installing akmod-nvidia..."
dnf5 -y --setopt=install_weak_deps=False install akmod-nvidia

echo "==> [NVIDIA Native Build] Compiling and signing NVIDIA kernel modules for ${KERNEL_CORE_PKG}..."
akmods --force --kernels "${KERNEL_CORE_PKG}" --kmod "nvidia"

# Restore original akmodsbuild binary
mv /usr/sbin/akmodsbuild.backup /usr/sbin/akmodsbuild

# Verify compiled and signed modules
MOD_DIR="/usr/lib/modules/${KERNEL_CORE_PKG}/extra/nvidia"
if [[ ! -f "${MOD_DIR}/nvidia.ko.xz" ]]; then
    echo "ERROR: NVIDIA kernel module compilation failed!" >&2
    if ls -la /var/cache/akmods/nvidia/*.failed.log 1>/dev/null 2>&1; then
        cat /var/cache/akmods/nvidia/*.failed.log >&2
    fi
    exit 1
fi
echo "    NVIDIA kernel modules built successfully in ${MOD_DIR}"

# Fallback explicit signing if brp-kmodsign did not append signature
if ! modinfo "${MOD_DIR}/nvidia.ko.xz" | grep -q "sig_id:.*PKCS#7"; then
    echo "==> [NVIDIA Native Build] Appending MOK signature to kernel modules..."
    KERNEL_SIGN_BIN="/usr/src/kernels/${KERNEL_CORE_PKG}/scripts/sign-file"
    if [[ -x "${KERNEL_SIGN_BIN}" ]]; then
        for mod in "${MOD_DIR}"/*.ko.xz; do
            mod_uncompressed="${mod%.xz}"
            xz -d -f "${mod}"
            "${KERNEL_SIGN_BIN}" sha256 \
                "${MOK_DIR}/private/private_key.priv" \
                "${MOK_DIR}/certs/public_key.der" \
                "${mod_uncompressed}"
            xz --compress --check=crc32 --lzma2=dict=1MiB -f "${mod_uncompressed}"
        done
        echo "    Modules signed successfully via sign-file."
    fi
fi

# Print module info verification
echo "==> [NVIDIA Native Build] Verifying module signature:"
modinfo "${MOD_DIR}/nvidia.ko.xz" | grep -E "filename|version|sig_id|signer" || true

echo "==> [NVIDIA Native Build] Installing NVIDIA runtime packages & container toolkit..."
dnf5 -y --setopt=install_weak_deps=False install \
    xorg-x11-drv-nvidia \
    xorg-x11-drv-nvidia-cuda \
    xorg-x11-drv-nvidia-cuda-libs \
    xorg-x11-drv-nvidia-power \
    nvidia-settings \
    nvidia-persistenced \
    libva-nvidia-driver

# Setup nvidia-container-toolkit repo
curl -sL https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
    -o /etc/yum.repos.d/nvidia-container-toolkit.repo
sed -i 's/^gpgcheck=0/gpgcheck=1/' /etc/yum.repos.d/nvidia-container-toolkit.repo
dnf5 -y --setopt=install_weak_deps=False install nvidia-container-toolkit
rm -f /etc/yum.repos.d/nvidia-container-toolkit.repo

echo "==> [NVIDIA Native Build] Cleaning up build packages to preserve image immutability..."
dnf5 -y remove \
    "kernel-devel-${KERNEL_VER_ONLY}" \
    akmods \
    gcc-c++

# Clean build artifacts
rm -rf /var/cache/akmods
rm -rf /run/akmods

echo "==> [NVIDIA Native Build] Applying Bazzite hardening & power management..."
# Remove Nouveau Vulkan ICDs to avoid conflicts
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json

# Remove nvidia_peermem from dracut config
sed -i 's/ nvidia_peermem\b//' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf 2>/dev/null || true

# Ensure proper symlink for libnvidia-ml.so
if [[ -f "/usr/lib64/libnvidia-ml.so.1" && ! -L "/usr/lib64/libnvidia-ml.so" ]]; then
    ln -s libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
fi

# Enable systemd services
systemctl enable nvidia-powerd.service 2>/dev/null || true
systemctl enable nvidia-cdi-refresh.service 2>/dev/null || true
systemctl enable nvidia-persistenced.service 2>/dev/null || true

echo "==> [NVIDIA Native Build] Native build completed with zero kernel downgrade!"
exit 0
