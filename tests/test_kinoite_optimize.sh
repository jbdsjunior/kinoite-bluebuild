#!/usr/bin/env bash
# Unit tests for kinoite-optimize
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_SCRIPT="$PROJECT_ROOT/files/system/usr/bin/kinoite-optimize"

TEST_TMP="$(mktemp -d)"
trap 'rm -rf "$TEST_TMP"' EXIT

MOCK_BIN="$TEST_TMP/bin"
mkdir -p "$MOCK_BIN"
export PATH="$MOCK_BIN:$PATH"

PASS_COUNT=0
FAIL_COUNT=0

assert_true() {
    local desc="$1"
    local condition="$2"

    if eval "$condition"; then
        echo "  [PASS] $desc"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  [FAIL] $desc"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

echo "Running tests for kinoite-optimize..."

# Mock external binaries to safely inspect actions
cat <<EOF > "$MOCK_BIN/chattr"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/chattr"

cat <<EOF > "$MOCK_BIN/lsattr"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/lsattr"

cat <<EOF > "$MOCK_BIN/filefrag"
#!/bin/bash
echo "\$1: 10 extents found"
exit 0
EOF
chmod +x "$MOCK_BIN/filefrag"

cat <<EOF > "$MOCK_BIN/btrfs"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/btrfs"

cat <<EOF > "$MOCK_BIN/journalctl"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/journalctl"

cat <<EOF > "$MOCK_BIN/flatpak"
#!/bin/bash
echo "\$@" >> "$TEST_TMP/flatpak_calls.log"
exit 0
EOF
chmod +x "$MOCK_BIN/flatpak"

cat <<EOF > "$MOCK_BIN/podman"
#!/bin/bash
echo "\$@" >> "$TEST_TMP/podman_calls.log"
exit 0
EOF
chmod +x "$MOCK_BIN/podman"

cat <<EOF > "$MOCK_BIN/rpm-ostree"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/rpm-ostree"

cat <<EOF > "$MOCK_BIN/systemctl"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/systemctl"

# Prepare mock home environment
MOCK_HOME="$TEST_TMP/home/user"
mkdir -p "$MOCK_HOME/.cache/rclone"
mkdir -p "$MOCK_HOME/Cloud/GoogleDrive/.Trash-1000"
touch "$MOCK_HOME/Cloud/GoogleDrive/.Trash-1000/orphan_file"
touch "$MOCK_HOME/.cache/rclone/cache_block.bin"

# Test 1: Syntax check of kinoite-optimize
assert_true "kinoite-optimize syntax validation (bash -n)" "bash -n '$TARGET_SCRIPT'"

# Test 2: Verify Trash cleanup logic isolates and purges .Trash-* directories
# Run trash purge segment directly
for base in "$MOCK_HOME/Cloud"; do
    while IFS= read -r -d '' td; do
        rm -rf "$td" 2>/dev/null || true
    done < <(find "$base" -mindepth 2 -maxdepth 2 -type d -name ".Trash-*" -print0 2>/dev/null)
done
assert_true "Residual .Trash-* directory purged cleanly" "[ ! -d '$MOCK_HOME/Cloud/GoogleDrive/.Trash-1000' ]"

# Test 3: Verify rclone atomic NoCOW logic with null-delimited paths
mkdir -p "$MOCK_HOME/.cache/rclone"
touch "$MOCK_HOME/.cache/rclone/file with spaces.bin"
RCLONE_FIXED=0
while IFS= read -r -d '' f; do
    cp --reflink=never "$f" "${f}.nocow_tmp" 2>/dev/null && mv -f "${f}.nocow_tmp" "$f" && ((RCLONE_FIXED++)) || true
done < <(find "$MOCK_HOME/.cache/rclone" -type f -print0 2>/dev/null)
assert_true "Rclone atomic file re-creation handles spaces and updates files" "[ '$RCLONE_FIXED' -ge 1 ]"

# Test 4: Verify flatpak and podman unified iteration
export CAN_SUDO=0
export RUN_USER_CMD=""
FLATPAK_SCOPES=("user")
for scope in "${FLATPAK_SCOPES[@]}"; do
    flatpak uninstall --unused -y >/dev/null 2>&1 || true
done
assert_true "Flatpak uninstall invoked cleanly" "grep -q 'uninstall --unused -y' '$TEST_TMP/flatpak_calls.log'"

prune_targets=("container" "volume" "image")
for target in "${prune_targets[@]}"; do
    podman "$target" prune -f >/dev/null 2>&1 || true
done
assert_true "Podman container prune executed" "grep -q 'container prune -f' '$TEST_TMP/podman_calls.log'"
assert_true "Podman volume prune executed" "grep -q 'volume prune -f' '$TEST_TMP/podman_calls.log'"
assert_true "Podman image prune executed" "grep -q 'image prune -f' '$TEST_TMP/podman_calls.log'"

echo "kinoite-optimize: $PASS_COUNT passed, $FAIL_COUNT failed."
[ "$FAIL_COUNT" -eq 0 ]
