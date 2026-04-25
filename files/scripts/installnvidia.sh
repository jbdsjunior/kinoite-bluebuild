#!/usr/bin/env bash
set -oue pipefail

mkdir -p /var/tmp
chmod 1777 /var/tmp

KERNEL_VERSION="$(rpm -q "kernel" --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
IMAGE_NAME="${IMAGE_NAME:-kinoite}"

# Adiciona repositórios
if [[ "$IMAGE_NAME" == *"open"* ]]; then
    curl -fLsS --retry 5 -o /etc/yum.repos.d/negativo17-fedora-nvidia.repo https://negativo17.org/repos/fedora-nvidia.repo
    sed -i '/^enabled=1/a\priority=90' /etc/yum.repos.d/negativo17-fedora-nvidia.repo
else
    curl -fLsS --retry 5 -o /etc/yum.repos.d/fedora-nvidia-580.repo https://negativo17.org/repos/fedora-nvidia-580.repo
    sed -i '/^enabled=1/a\priority=90' /etc/yum.repos.d/fedora-nvidia-580.repo
    if [ -f /etc/yum.repos.d/fedora-multimedia.repo ]; then
        sed -i 's/^enabled=.*/enabled=0/' /etc/yum.repos.d/fedora-multimedia.repo
    fi
fi

# Instala dependências de compilação
dnf install -y --setopt=install_weak_deps=False "kernel-devel-matched-$(rpm -q 'kernel' --queryformat '%{VERSION}')"
dnf install -y --setopt=install_weak_deps=False akmods gcc-c++ nvidia-kmod-common nvidia-modprobe

echo "Compilando driver NVIDIA (isso pode demorar)..."
akmods --force --kernels "${KERNEL_VERSION}" --kmod "nvidia"

# Verifica se a compilação gerou os arquivos
modinfo /usr/lib/modules/${KERNEL_VERSION}/extra/nvidia/nvidia{,-drm,-modeset,-peermem,-uvm}.ko.xz > /dev/null || \
    (cat "/var/cache/akmods/nvidia/*.failed.log" && exit 1)

# Chama o script de assinatura (garante que ele use o mesmo diretório deste script)
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
bash "$SCRIPT_DIR/signmodules.sh" "nvidia"

# Instala pacotes do usuário
nvidia_packages_list=(
    'nvidia-driver'
    'nvidia-persistenced'
    'nvidia-settings'
    'nvidia-driver-cuda'
    'nvidia-container-toolkit'
    'libnvidia-fbc'
    'libva-nvidia-driver'
)

curl -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo -o /etc/yum.repos.d/nvidia-container-toolkit.repo
sed -i 's/^gpgcheck=0/gpgcheck=1/' /etc/yum.repos.d/nvidia-container-toolkit.repo
sed -i 's/^enabled=0.*/enabled=1/' /etc/yum.repos.d/nvidia-container-toolkit.repo

dnf -y --setopt=install_weak_deps=False install "${nvidia_packages_list[@]}"

# Políticas SELinux
curl -L https://raw.githubusercontent.com/NVIDIA/dgx-selinux/master/bin/RHEL9/nvidia-container.pp -o nvidia-container.pp
semodule -i nvidia-container.pp

# Limpeza profunda
dnf -y remove akmod-nvidia akmods kernel-devel kernel-headers gcc-c++
rm -f nvidia-container.pp /etc/yum.repos.d/nvidia-container-toolkit.repo /etc/yum.repos.d/fedora-nvidia-580.repo /etc/yum.repos.d/negativo17-fedora-nvidia.repo

if [ -f /etc/yum.repos.d/fedora-multimedia.repo ]; then
    sed -i 's/^enabled=.*/enabled=1/' /etc/yum.repos.d/fedora-multimedia.repo
fi

# REMOVE AS CHAVES PRIVADAS DEPOIS DE USAR PARA NÃO VAZAR NA IMAGEM
rm -rf /tmp/certs/