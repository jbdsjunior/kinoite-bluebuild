#!/usr/bin/env bash
# =====================================================================
# Host Sanitation Script: Clean /etc Configuration Drift
# Audited against: docs/diff.logs (ostree admin config-diff)
# Aligns host configuration with kinoite-bluebuild declarative baseline
# =====================================================================
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
  echo "Error: this script must be run as root (sudo)." >&2
  exit 1
fi

echo "==> [1/5] Purging transient systemd cgroup resource limit drop-ins..."
if [ -d "/etc/systemd/system.control" ]; then
  rm -rf /etc/systemd/system.control
  echo "    Removed /etc/systemd/system.control"
fi

echo "==> [2/5] Purging redundant and insecure udev rules..."
if [ -f "/etc/udev/rules.d/70-vxe.rules" ]; then
  rm -f /etc/udev/rules.d/70-vxe.rules
  echo "    Removed /etc/udev/rules.d/70-vxe.rules (superseded by /usr/lib/udev/rules.d/70-peripherals.rules)"
fi

echo "==> [3/5] Purging rogue and unmanaged YUM/DNF repositories..."
for repo in \
  "/etc/yum.repos.d/rpmfusion-nonfree-nvidia-driver.repo" \
  "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo" \
  "/etc/yum.repos.d/rpmfusion-nonfree-steam.repo"; do
  if [ -f "${repo}" ]; then
    rm -f "${repo}"
    echo "    Removed ${repo}"
  fi
done

echo "==> [4/5] Purging stale installer artifacts, setup markers, and spooler backups..."
for artifact in \
  "/etc/plasma-setup-done" \
  "/etc/.linuxbrew" \
  "/etc/.fedora-kinoite-plasmalogin-workaround" \
  "/etc/.rpm-ostree-shadow-mode-fixed2.stamp" \
  "/etc/foomatic/hashes.d/hashes.new" \
  "/etc/foomatic/hashes.d/hashes.foomatic-opt-update" \
  "/etc/cups/subscriptions.conf.O" \
  "/etc/sysconfig/anaconda"; do
  if [ -f "${artifact}" ]; then
    rm -f "${artifact}"
    echo "    Removed ${artifact}"
  fi
done

echo "==> [5/5] Reloading daemons and restoring time synchronization..."
systemctl daemon-reload
udevadm control --reload-rules
udevadm trigger
systemctl enable --now chronyd

echo ""
echo "==> Verification:"
timedatectl status | grep -E "NTP service|System clock synchronized" || true
echo ""
echo "Host /etc sanitation completed successfully."
