#!/usr/bin/env bash
# Unit tests for kinoite-setup-tpm
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_SCRIPT="$PROJECT_ROOT/files/system/usr/bin/kinoite-setup-tpm"

TEST_TMP="$(mktemp -d)"
trap 'rm -rf "$TEST_TMP"' EXIT

MOCK_BIN="$TEST_TMP/bin"
mkdir -p "$MOCK_BIN"
export PATH="$MOCK_BIN:$PATH"

PASS_COUNT=0
FAIL_COUNT=0

assert_exit_code() {
    local desc="$1"
    local expected_code="$2"
    shift 2

    local code=0
    "$@" >/dev/null 2>&1 || code=$?

    if [ "$code" -eq "$expected_code" ]; then
        echo "  [PASS] $desc (expected: $expected_code, got: $code)"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  [FAIL] $desc (expected: $expected_code, got: $code)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

echo "Running tests for kinoite-setup-tpm..."

# Test 1: Non-root execution should fail with exit code 1
# id command returning non-zero
cat <<EOF > "$MOCK_BIN/id"
#!/bin/bash
echo 1000
EOF
chmod +x "$MOCK_BIN/id"

assert_exit_code "Non-root user should be rejected" 1 bash "$TARGET_SCRIPT" /dev/dummy

# Setup root mock
cat <<EOF > "$MOCK_BIN/id"
#!/bin/bash
echo 0
EOF
chmod +x "$MOCK_BIN/id"

# Test 2: No device parameter provided should fail
assert_exit_code "Missing device parameter should fail" 1 bash "$TARGET_SCRIPT"

# Test 3: Device not a block device should fail
assert_exit_code "Non-block device should fail" 1 bash "$TARGET_SCRIPT" /dev/non_existent_fake_disk

# Test 4: Device is not a LUKS partition
# Create a dummy regular file and mock test -b
DUMMY_DEV="$TEST_TMP/fake_blk"
touch "$DUMMY_DEV"

cat <<EOF > "$MOCK_BIN/cryptsetup"
#!/bin/bash
if [ "\$1" = "isLuks" ]; then
    exit 1
fi
exit 0
EOF
chmod +x "$MOCK_BIN/cryptsetup"

# Run with custom wrapper bypassing the -b bash check for unit test isolation
assert_exit_code "Invalid LUKS partition should fail" 1 bash -c '
    source <(sed "s/\[ ! -b \"\$DEVICE\" \]/false/" "'"$TARGET_SCRIPT"'") '"$DUMMY_DEV"'
'

# Test 5: Successful execution flow with LUKS and TPM2 mocks
cat <<EOF > "$MOCK_BIN/cryptsetup"
#!/bin/bash
if [ "\$1" = "isLuks" ]; then
    exit 0
elif [ "\$1" = "luksUUID" ]; then
    echo "12345678-1234-1234-1234-123456789abc"
    exit 0
fi
exit 0
EOF
chmod +x "$MOCK_BIN/cryptsetup"

cat <<EOF > "$MOCK_BIN/systemd-cryptenroll"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/systemd-cryptenroll"

cat <<EOF > "$MOCK_BIN/rpm-ostree"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/rpm-ostree"

cat <<EOF > "$MOCK_BIN/dracut"
#!/bin/bash
exit 0
EOF
chmod +x "$MOCK_BIN/dracut"

# Mock /etc/crypttab inside test environment by replacing /etc/crypttab path in subshell
MOCK_CRYPTTAB="$TEST_TMP/crypttab"
echo "luks-12345678-1234-1234-1234-123456789abc UUID=12345678-1234-1234-1234-123456789abc none discard" > "$MOCK_CRYPTTAB"

assert_exit_code "Valid LUKS enrollment flow with crypttab update" 0 bash -c '
    source <(sed -e "s/\[ ! -b \"\$DEVICE\" \]/false/" -e "s|/etc/crypttab|'"$MOCK_CRYPTTAB"'|g" "'"$TARGET_SCRIPT"'") '"$DUMMY_DEV"' --skip-recovery-key
'

if grep -q "tpm2-device=auto" "$MOCK_CRYPTTAB"; then
    echo "  [PASS] /etc/crypttab entry appended with tpm2-device=auto"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "  [FAIL] /etc/crypttab entry missing tpm2-device=auto"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo "kinoite-setup-tpm: $PASS_COUNT passed, $FAIL_COUNT failed."
[ "$FAIL_COUNT" -eq 0 ]
