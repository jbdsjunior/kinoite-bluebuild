#!/bin/bash
set -euo pipefail

# Required groups for virtualization
REQUIRED_GROUPS="libvirt,kvm"
# Directories for VM images
SYSTEM_IMAGES_DIR="/var/lib/libvirt/images"
TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"

apply_nocow_if_btrfs() {
  local path="$1"
  local fs_type
  fs_type=$(stat -f -c %T "$path")

  if [[ "$fs_type" != "btrfs" ]]; then
    echo "Skipping No_COW on $path (filesystem: $fs_type)."
    return 0
  fi

  sudo chattr +C "$path"
}

echo "Configuring KVM and Libvirt..."

# Add current user to necessary groups
if [[ "$TARGET_USER" == "root" ]]; then
  echo "Refusing to change groups for root. Run this script as your regular user (without sudo)."
  exit 1
fi
sudo usermod -aG "$REQUIRED_GROUPS" "$TARGET_USER"

# Setup system-wide images directory with No_COW (important for BTRFS performance)
sudo mkdir -p "$SYSTEM_IMAGES_DIR"
apply_nocow_if_btrfs "$SYSTEM_IMAGES_DIR"

# Restart the service to apply changes
sudo systemctl restart libvirtd

echo "Setup complete for user '$TARGET_USER'. Log out and log in again to apply new group permissions."
