#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
printf '[aviso] "%s" foi descontinuado. Use "%s".\n' "mantence.sh" "maintenance.sh" >&2
exec "${SCRIPT_DIR}/maintenance.sh" "$@"
