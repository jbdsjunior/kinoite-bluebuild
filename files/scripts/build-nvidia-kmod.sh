#!/usr/bin/env bash
# ==============================================================================
# Native NVIDIA Kernel Module Builder (Zero Downgrade Policy)
# Inspired by BlueBuild Base Images PR #46 & Universal Blue Bazzite
# ==============================================================================
set -euo pipefail

echo "==> [NVIDIA Native Build] Detecting installed kernel version..."
KERNEL_CORE_PKG=$(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')
KERNEL_VER_ONLY=$(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}')
echo "    Target kernel: ${KERNEL_CORE_PKG}"

echo "==> [NVIDIA Native Build] Enabling RPM Fusion Nonfree & installing akmods..."
dnf5 -y install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-45.noarch.rpm

dnf5 -y --setopt=install_weak_deps=False install \
    "kernel-devel-${KERNEL_VER_ONLY}" \
    akmods \
    gcc-c++

# In Fedora container builds running as root, akmodsbuild checks [[ -w /var ]]
# and aborts with "ERROR: Not to be used as root". Exactly like upstream BlueBuild PR #46:
cp /usr/sbin/akmodsbuild /usr/sbin/akmodsbuild.backup
sed -i '/if \[\[ -w \/var \]\] ; then/,/fi/d' /usr/sbin/akmodsbuild

echo "==> [NVIDIA Native Build] Installing akmod-nvidia..."
dnf5 -y --setopt=install_weak_deps=False install akmod-nvidia

echo "==> [NVIDIA Native Build] Compiling NVIDIA kernel modules for ${KERNEL_CORE_PKG}..."
akmods --force --kernels "${KERNEL_CORE_PKG}" --kmod "nvidia"

# Restore original akmodsbuild binary
mv /usr/sbin/akmodsbuild.backup /usr/sbin/akmodsbuild

# Verify compiled modules
MOD_DIR="/usr/lib/modules/${KERNEL_CORE_PKG}/extra/nvidia"
if [[ ! -f "${MOD_DIR}/nvidia.ko.xz" ]]; then
    echo "ERROR: NVIDIA kernel module compilation failed!" >&2
    if ls -la /var/cache/akmods/nvidia/*.failed.log 1>/dev/null 2>&1; then
        cat /var/cache/akmods/nvidia/*.failed.log >&2
    fi
    exit 1
fi
echo "    NVIDIA kernel modules built successfully in ${MOD_DIR}"

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

echo "==> [NVIDIA Native Build] Native build completed with zero kernel downgrade!"
exit 0
