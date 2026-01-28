#!/bin/bash
set -euo pipefail

# Required groups for virtualization
REQUIRED_GROUPS="libvirt,kvm"
# Directories for VM images
SYSTEM_IMAGES_DIR="/var/lib/libvirt/images"
USER_IMAGES_DIR="$HOME/.local/share/libvirt/images"

echo "Configuring KVM and Libvirt..."

# Add current user to necessary groups
sudo usermod -aG "$REQUIRED_GROUPS" "$USER"

# Setup system-wide images directory with No_COW (important for BTRFS performance)
sudo mkdir -p "$SYSTEM_IMAGES_DIR"
sudo chattr +C "$SYSTEM_IMAGES_DIR"

# Restart the service to apply changes
sudo systemctl restart libvirtd

echo "Setup complete. Please restart your system to apply user group permissions."