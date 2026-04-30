#!/bin/bash
set -euo pipefail

# Immutable host post-install health check.
# Safe to run multiple times and does not mutate system state.

failures=0

check_cmd() {
  local name="$1"
  shift
  if "$@"; then
    echo "[OK] ${name}"
  else
    echo "[FAIL] ${name}" >&2
    failures=$((failures + 1))
  fi
}

check_cmd "rpm-ostreed staged policy" grep -q '^AutomaticUpdatePolicy=stage$' /usr/lib/rpm-ostreed.conf.d/60-daemon-policy.conf
check_cmd "topgrade timer visible" systemctl --user list-unit-files topgrade-update.timer
check_cmd "topgrade timer enabled" systemctl --user is-enabled topgrade-update.timer
check_cmd "podman available" command -v podman
check_cmd "podman info" podman info >/dev/null

if [[ $failures -gt 0 ]]; then
  echo "Health check finished with ${failures} failure(s)." >&2
  exit 1
fi

echo "Health check finished successfully."
