#!/bin/bash
set -euo pipefail

REQUIRED_GROUPS="libvirt,kvm"
SYSTEM_IMAGES_DIR="/var/lib/libvirt/images"
TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd"
    exit 1
  fi
}

apply_nocow_if_btrfs() {
  local path="$1"
  local fs_type
  fs_type=$(stat -f -c %T "$path")

  if [[ "$fs_type" != "btrfs" ]]; then
    echo "Skipping No_COW on $path (filesystem: $fs_type)."
    return 0
  fi

  if lsattr -d "$path" 2>/dev/null | grep -q 'C'; then
    echo "No_COW already enabled on $path."
    return 0
  fi

  if ! sudo chattr +C "$path"; then
    echo "Warning: unable to set No_COW on $path (directory may not be empty)."
  fi
}

echo "Configuring KVM and Libvirt..."
require_command sudo
require_command usermod
require_command stat
require_command chattr
require_command lsattr

if [[ "$TARGET_USER" == "root" ]]; then
  echo "Refusing to change groups for root. Run this script as your regular user (without sudo)."
  exit 1
fi

sudo usermod -aG "$REQUIRED_GROUPS" "$TARGET_USER"

sudo mkdir -p "$SYSTEM_IMAGES_DIR"
apply_nocow_if_btrfs "$SYSTEM_IMAGES_DIR"

if systemctl list-unit-files | grep -q '^libvirtd\.service'; then
  sudo systemctl restart libvirtd
else
  echo "Warning: libvirtd.service was not found; skipping restart."
fi

echo "Setup complete for user '$TARGET_USER'. Log out and log in again to apply new group permissions."
