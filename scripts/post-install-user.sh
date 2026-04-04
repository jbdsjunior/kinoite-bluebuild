#!/usr/bin/env bash
# Post-install user configuration script
# Apply tmpfs overrides for Flatpak browser caches

set -euo pipefail

# Apply tmpfs mounts for browser caches (reduces NVMe wear)
flatpak override --user --tmpfs=~/.var/app/com.brave.Browser/cache com.brave.Browser 2>/dev/null || true
flatpak override --user --tmpfs=~/.var/app/com.google.Chrome/cache com.google.Chrome 2>/dev/null || true

echo "Flatpak tmpfs overrides applied successfully"
