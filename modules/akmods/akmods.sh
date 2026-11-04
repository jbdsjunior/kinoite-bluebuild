#!/usr/bin/env bash
set -euo pipefail

ENABLE_AKMODS_REPO() {
  akmods_repo="$(find /etc/yum.repos.d -type f -exec grep -l '\[copr:copr.fedorainfracloud.org:ublue-os:akmods\]' {} +)"
  if [[ -n "${akmods_repo}" ]]; then
    sed -i 's@enabled=0@enabled=1@g' "${akmods_repo}"
  fi
}

INSTALL_RPM_FUSION() {
if ! rpm -q rpmfusion-free-release &>/dev/null && ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
  if command -v dnf5 &> /dev/null; then
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${OS_VERSION}.noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${OS_VERSION}.noarch.rpm
  elif command -v rpm-ostree &> /dev/null; then
    rpm-ostree install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${OS_VERSION}.noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${OS_VERSION}.noarch.rpm
  fi
  previously_not_installed_rpm_fusion=true
else
  previously_not_installed_rpm_fusion=false
fi
}

UNINSTALL_RPM_FUSION() {
if "${previously_not_installed_rpm_fusion}"; then
  if command -v dnf5 &> /dev/null; then
    dnf5 -y remove rpmfusion-free-release rpmfusion-nonfree-release
  elif command -v rpm-ostree &> /dev/null; then
    rpm-ostree uninstall rpmfusion-free-release rpmfusion-nonfree-release
  fi
fi
}

SYNC_KERNEL() {
  local target_kernel=""
  local kmod_rpms=(/tmp/akmods/kmods/kmod-*.rpm /tmp/akmods-rpms/kmods/kmod-*.rpm /tmp/rpms/kmods/kmod-*.rpm)
  for rpm in "${kmod_rpms[@]}"; do
    [[ -f "$rpm" ]] || continue
    local filename
    filename=$(basename "$rpm")
    if [[ "$filename" =~ ^kmod-[^-]+-([0-9]+\.[0-9]+\.[0-9]+-[0-9]+\.fc[0-9]+(\.[^.]+)?)-.*\.rpm$ ]]; then
      target_kernel="${BASH_REMATCH[1]}"
      break
    fi
  done

  if [[ -z "$target_kernel" ]]; then
    echo "No target kernel version detected from akmods kmod packages; skipping kernel synchronization."
    return 0
  fi

  local current_kernel
  current_kernel=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-core 2>/dev/null || true)
  echo "Current container kernel: ${current_kernel}"
  echo "Required akmods kernel:   ${target_kernel}"

  if [[ "$current_kernel" == "$target_kernel" ]]; then
    echo "Kernel is already synchronized with akmods (${target_kernel})."
    return 0
  fi

  echo "Synchronizing container kernel to match akmods (${target_kernel})..."
  local kernel_rpms=(/tmp/kernel-rpms/*.rpm)
  if compgen -G "/tmp/kernel-rpms/*.rpm" >/dev/null; then
    echo "Found matching kernel RPMs in /tmp/kernel-rpms/."
  else
    mkdir -p /tmp/kernel-rpms
    if compgen -G "/tmp/akmods/kernel-rpms/*.rpm" >/dev/null; then
      echo "Copying matching kernel RPMs from /tmp/akmods/kernel-rpms/..."
      cp -r /tmp/akmods/kernel-rpms/*.rpm /tmp/kernel-rpms/
    else
      echo "Fetching matching kernel RPMs for ${target_kernel} from koji..."
      local k_ver k_rel
      k_ver=$(echo "$target_kernel" | cut -d'-' -f1)
      k_rel=$(echo "$target_kernel" | cut -d'-' -f2 | sed 's/\.x86_64//')
      for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do
        curl -fLsS --retry 3 -o "/tmp/kernel-rpms/${pkg}-${target_kernel}.rpm" \
          "https://kojipkgs.fedoraproject.org//packages/kernel/${k_ver}/${k_rel}/x86_64/${pkg}-${target_kernel}.rpm"
      done
    fi
  fi

  if command -v dnf5 &>/dev/null; then
    dnf5 -y install --allow-downgrade /tmp/kernel-rpms/*.rpm
  elif command -v rpm-ostree &>/dev/null; then
    rpm-ostree override replace /tmp/kernel-rpms/*.rpm
  fi
  echo "Kernel synchronization complete: $(rpm -q kernel-core)"
}

INSTALL_NVIDIA_DRIVER() {
BASE_IMAGE_NAME=${BASE_IMAGE##*/}
BASE_IMAGE_NAME=${BASE_IMAGE_NAME%-*}

# Fetch Common AKMODS & Kernel RPMS
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods:"${KERNEL_BASE}"-"$(rpm -E %fedora)" dir:/tmp/akmods
AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/

echo "Pulling akmods nvidia image"
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-"${NVIDIA_DRIVER}":"${KERNEL_BASE}"-"$(rpm -E %fedora)" dir:/tmp/akmods-rpms

NVIDIA_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods-rpms/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods-rpms/"$NVIDIA_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods-rpms/

# Synchronize kernel with required akmods version if mismatched
SYNC_KERNEL

# Install Nvidia RPMs
IMAGE_NAME="${BASE_IMAGE_NAME}" RPMFUSION_MIRROR="" /tmp/akmods-rpms/ublue-os/nvidia-install.sh
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so

KARGS_D="/usr/lib/bootc/kargs.d"
BLUEBUILD_NVIDIA_TOML="${KARGS_D}/00-bluebuild-nvidia-kargs.toml"

# Create kargs folder if doesn't exist
mkdir -p "${KARGS_D}"
echo 'kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]' >> "${BLUEBUILD_NVIDIA_TOML}"
}

INSTALL_NVIDIA=false
NVIDIA_DRIVER=""
get_json_array INSTALL 'try .["install"][]' "$1"

KERNEL_BASE=$(echo "$1" | jq -r 'try .["base"]')
if [[ -z $KERNEL_BASE || $KERNEL_BASE == "null" ]]; then
	KERNEL_BASE="main"
fi

NVIDIA_DRIVER=$(echo "$1" | jq -r 'try .["nvidia-driver"]')
if [[ $NVIDIA_DRIVER == "nvidia" || $NVIDIA_DRIVER == "nvidia-open" ]]; then
    INSTALL_NVIDIA=true

    if [[ "$NVIDIA_DRIVER" == *"open"* ]]; then
        echo "nvidia-open kernel driver selected"
    else
        echo "nvidia-lts kernel driver selected"
        curl -fLsS --retry 5 -o /etc/yum.repos.d/fedora-nvidia-580.repo https://negativo17.org/repos/fedora-nvidia-580.repo
        sed -i '/^enabled=1/a\priority=90' /etc/yum.repos.d/fedora-nvidia-580.repo
        NVIDIA_DRIVER="nvidia-lts"
    fi
fi


if [[ ${#INSTALL[@]} -lt 1 && $INSTALL_NVIDIA == false ]]; then
  echo "ERROR: You didn't specify any akmod or nvidia driver for installation!"
  exit 1
fi

INSTALL_PATH=("${INSTALL[@]/#/\/tmp/rpms/kmods/*}")
INSTALL_PATH=("${INSTALL_PATH[@]/%/*.rpm}")
INSTALL_STR=$(echo "${INSTALL_PATH[*]}" | tr -d '\n')

# Universal Blue switched from RPMFusion to negativo17 repos
# WL & V4L2Loopback akmods currently require RPMFusion repo, so we temporarily install then uninstall it

echo "Installing akmods"

echo "Total length of modules to install: ${#INSTALL[@]}"
if [[ ${#INSTALL[@]} -gt 0 ]]; then
    echo "Installing: $(echo "${INSTALL[*]}" | tr -d '\n')"
    ENABLE_AKMODS_REPO
    INSTALL_RPM_FUSION
    rpm-ostree install ${INSTALL_STR}
    UNINSTALL_RPM_FUSION
fi

if [[ $INSTALL_NVIDIA == true ]]; then
    echo "Installing nvidia driver: $NVIDIA_DRIVER"
    INSTALL_NVIDIA_DRIVER
fi
