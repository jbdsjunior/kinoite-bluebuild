#!/usr/bin/env bash
set -oue pipefail

mkdir -p /var/tmp
chmod 1777 /var/tmp

IMAGE_NAME="${IMAGE_NAME:-kinoite}"

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

# 1. Extrai as versões exatas do Kernel atual da imagem
K_VER="$(rpm -q kernel --queryformat '%{VERSION}')"
K_REL="$(rpm -q kernel --queryformat '%{RELEASE}')"
K_ARCH="$(rpm -q kernel --queryformat '%{ARCH}')"
KERNEL_VERSION="${K_VER}-${K_REL}.${K_ARCH}"

echo "=> Preparando headers para o kernel: ${KERNEL_VERSION}"

# 2. Tenta instalar do DNF. Se não achar (mirror desatualizado), baixa direto do Koji.
if ! dnf install -y --allowerasing --setopt=install_weak_deps=False "kernel-devel-${KERNEL_VERSION}" "kernel-devel-matched-${K_VER}"; then
    echo "⚠️ Versão do kernel ausente nos mirrors do DNF. Sincronismo detectado."
    echo "📥 Baixando RPMs de desenvolvimento diretamente do Fedora Koji Build System..."
    
    URL_DEVEL="https://kojipkgs.fedoraproject.org/packages/kernel/${K_VER}/${K_REL}/${K_ARCH}/kernel-devel-${KERNEL_VERSION}.rpm"
    URL_MATCHED="https://kojipkgs.fedoraproject.org/packages/kernel/${K_VER}/${K_REL}/${K_ARCH}/kernel-devel-matched-${KERNEL_VERSION}.rpm"
    
    dnf install -y "$URL_DEVEL" "$URL_MATCHED"
fi

# 3. Instala as ferramentas de compilação
dnf install -y --allowerasing --setopt=install_weak_deps=False akmods gcc-c++

# 4. HACK CRÍTICO: Permite que o akmods corra como root dentro do container OCI
cp /usr/sbin/akmodsbuild /usr/sbin/akmodsbuild.backup
sed -i '/if \[\[ -w \/var \]\] ; then/,/fi/d' /usr/sbin/akmodsbuild

# 5. Instala os pacotes da NVIDIA para compilação do módulo
dnf install -y --allowerasing --setopt=install_weak_deps=False nvidia-kmod-common nvidia-modprobe akmod-nvidia

# 6. Restaura o ficheiro original do akmodsbuild
mv /usr/sbin/akmodsbuild.backup /usr/sbin/akmodsbuild

echo "Compilando driver NVIDIA via akmods (isso pode demorar)..."
akmods --force --kernels "${KERNEL_VERSION}" --kmod "nvidia"

# Verifica se os módulos foram gerados antes de avançar para a assinatura
shopt -s nullglob
MODULES=(/usr/lib/modules/${KERNEL_VERSION}/extra/nvidia/nvidia*.ko*)
if [ ${#MODULES[@]} -eq 0 ]; then
    echo "ERRO CRÍTICO: Módulos NVIDIA não foram gerados pelo akmods."
    cat /var/cache/akmods/nvidia/*.failed.log || true
    exit 1
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
bash "$SCRIPT_DIR/signmodules.sh" "nvidia"

# 7. Instalação final das ferramentas e utilitários Nvidia
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

dnf install -y --allowerasing --setopt=install_weak_deps=False "${nvidia_packages_list[@]}"

curl -L https://raw.githubusercontent.com/NVIDIA/dgx-selinux/master/bin/RHEL9/nvidia-container.pp -o nvidia-container.pp
semodule -i nvidia-container.pp

# 8. Limpeza pesada
dnf remove -y akmod-nvidia akmods kernel-devel kernel-devel-matched kernel-headers gcc-c++
rm -f nvidia-container.pp /etc/yum.repos.d/nvidia-container-toolkit.repo /etc/yum.repos.d/fedora-nvidia-580.repo /etc/yum.repos.d/negativo17-fedora-nvidia.repo

if [ -f /etc/yum.repos.d/fedora-multimedia.repo ]; then
    sed -i 's/^enabled=.*/enabled=1/' /etc/yum.repos.d/fedora-multimedia.repo
fi
