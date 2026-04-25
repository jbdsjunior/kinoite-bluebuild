#!/usr/bin/env bash
set -oue pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
readonly IMAGE_NAME="${IMAGE_NAME:-kinoite}"

NVIDIA_REPO_FILE=""
MULTIMEDIA_REPO_FILE="/etc/yum.repos.d/fedora-multimedia.repo"

cleanup() {
    if [[ -n "${NVIDIA_REPO_FILE}" && -f "${NVIDIA_REPO_FILE}" ]]; then
        rm -f "${NVIDIA_REPO_FILE}"
    fi

    rm -f /etc/yum.repos.d/nvidia-container-toolkit.repo nvidia-container.pp

    if [[ -f "${MULTIMEDIA_REPO_FILE}" ]]; then
        sed -i 's/^enabled=.*/enabled=1/' "${MULTIMEDIA_REPO_FILE}"
    fi
}

prepare_tmp() {
    mkdir -p /var/tmp
    chmod 1777 /var/tmp
}

get_kernel_release() {
    rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -V | tail -n1
}

get_kernel_version() {
    rpm -q kernel --queryformat '%{VERSION}\n' | sort -V | tail -n1
}

configure_negativo17_repo() {
    local repo_url

    if [[ "${IMAGE_NAME}" == *"open"* ]]; then
        repo_url="https://negativo17.org/repos/fedora-nvidia.repo"
        NVIDIA_REPO_FILE="/etc/yum.repos.d/negativo17-fedora-nvidia.repo"
    else
        repo_url="https://negativo17.org/repos/fedora-nvidia-580.repo"
        NVIDIA_REPO_FILE="/etc/yum.repos.d/fedora-nvidia-580.repo"
    fi

    curl -fLsS --retry 5 -o "${NVIDIA_REPO_FILE}" "${repo_url}"
    sed -i '/^enabled=1/a\priority=90' "${NVIDIA_REPO_FILE}"

    if [[ -f "${MULTIMEDIA_REPO_FILE}" ]]; then
        sed -i 's/^enabled=.*/enabled=0/' "${MULTIMEDIA_REPO_FILE}"
    fi
}

patch_akmodsbuild() {
    cp /usr/sbin/akmodsbuild /usr/sbin/akmodsbuild.backup
    sed -i '/if \[\[ -w \/var \]\] ; then/,/fi/d' /usr/sbin/akmodsbuild
}

restore_akmodsbuild() {
    if [[ -f /usr/sbin/akmodsbuild.backup ]]; then
        mv /usr/sbin/akmodsbuild.backup /usr/sbin/akmodsbuild
    fi
}

install_build_dependencies() {
    local kernel_release="$1"
    local kernel_version="$2"
    local installed=0

    local -a kernel_devel_candidates=(
        "kernel-devel-matched-${kernel_release}"
        "kernel-devel-matched-${kernel_version}"
        "kernel-devel-${kernel_release}"
        "kernel-devel-${kernel_version}"
        "kernel-devel"
    )

    for pkg in "${kernel_devel_candidates[@]}"; do
        if dnf install -y --allowerasing --setopt=install_weak_deps=False "${pkg}"; then
            installed=1
            break
        fi
    done

    if [[ "${installed}" -eq 0 ]]; then
        echo "ERRO CRÍTICO: não foi possível instalar um pacote kernel-devel compatível com ${kernel_release}."
        return 1
    fi

    dnf install -y --allowerasing --setopt=install_weak_deps=False akmods gcc-c++
}

build_nvidia_module() {
    local kernel_release="$1"

    echo "Compilando driver NVIDIA para o kernel ${kernel_release} (isso pode demorar)..."
    akmods --force --kernels "${kernel_release}" --kmod "nvidia"
}

verify_nvidia_modules() {
    local kernel_release="$1"

    shopt -s nullglob
    local modules=(/usr/lib/modules/"${kernel_release}"/extra/nvidia/nvidia*.ko*)
    if [[ ${#modules[@]} -eq 0 ]]; then
        echo "ERRO CRÍTICO: módulos NVIDIA não foram gerados pelo akmods para ${kernel_release}."
        cat /var/cache/akmods/nvidia/*.failed.log || true
        exit 1
    fi
}

install_runtime_nvidia_stack() {
    local nvidia_packages_list=(
        nvidia-driver
        nvidia-persistenced
        nvidia-settings
        nvidia-driver-cuda
        nvidia-container-toolkit
        libnvidia-fbc
        libva-nvidia-driver
    )

    curl -fLsS --retry 5 -o /etc/yum.repos.d/nvidia-container-toolkit.repo \
        https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo
    sed -i 's/^gpgcheck=0/gpgcheck=1/' /etc/yum.repos.d/nvidia-container-toolkit.repo
    sed -i 's/^enabled=0.*/enabled=1/' /etc/yum.repos.d/nvidia-container-toolkit.repo

    dnf install -y --allowerasing --setopt=install_weak_deps=False "${nvidia_packages_list[@]}"

    curl -fLsS --retry 5 -o nvidia-container.pp \
        https://raw.githubusercontent.com/NVIDIA/dgx-selinux/master/bin/RHEL9/nvidia-container.pp
    semodule -i nvidia-container.pp
}

remove_build_dependencies() {
    dnf remove -y akmod-nvidia akmods kernel-devel kernel-headers gcc-c++
}

trap 'restore_akmodsbuild; cleanup' EXIT

prepare_tmp
configure_negativo17_repo

KERNEL_RELEASE="$(get_kernel_release)"
KERNEL_VERSION="$(get_kernel_version)"

install_build_dependencies "${KERNEL_RELEASE}" "${KERNEL_VERSION}"
patch_akmodsbuild

dnf install -y --allowerasing --setopt=install_weak_deps=False nvidia-kmod-common nvidia-modprobe akmod-nvidia

restore_akmodsbuild
build_nvidia_module "${KERNEL_RELEASE}"
verify_nvidia_modules "${KERNEL_RELEASE}"
bash "${SCRIPT_DIR}/signmodules.sh" "nvidia" "${KERNEL_RELEASE}"
install_runtime_nvidia_stack
remove_build_dependencies

echo "Instalação NVIDIA concluída para kernel ${KERNEL_RELEASE}."
