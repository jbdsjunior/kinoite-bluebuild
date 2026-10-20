#!/usr/bin/env bash
# Unit tests for network-guard
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_SCRIPT="$PROJECT_ROOT/files/system/usr/libexec/kinoite/network-guard"

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

# Create mock busctl wrapper
create_mock_busctl() {
    local metered_val="$1"
    local conn_val="$2"

    cat <<EOF > "$MOCK_BIN/busctl"
#!/bin/bash
if [[ "\$*" == *"Metered"* ]]; then
    echo "u $metered_val"
    exit 0
elif [[ "\$*" == *"Connectivity"* ]]; then
    echo "u $conn_val"
    exit 0
fi
exit 1
EOF
    chmod +x "$MOCK_BIN/busctl"
}

echo "Running tests for network-guard..."

# Case 1: Unmetered (2) + Full Connectivity (4) -> OK (0)
create_mock_busctl 2 4
assert_exit_code "Unmetered (2) and Full connectivity (4) should succeed" 0 bash "$TARGET_SCRIPT"

# Case 2: Metered (1) + Full Connectivity (4) -> Block (1)
create_mock_busctl 1 4
assert_exit_code "Metered (1) should block updates" 1 bash "$TARGET_SCRIPT"

# Case 3: Guess Metered (3) + Full Connectivity (4) -> Block (1)
create_mock_busctl 3 4
assert_exit_code "Guess metered (3) should block updates" 1 bash "$TARGET_SCRIPT"

# Case 4: Guess Unmetered (4) + Full Connectivity (4) -> OK (0)
create_mock_busctl 4 4
assert_exit_code "Guess unmetered (4) and Full connectivity (4) should succeed" 0 bash "$TARGET_SCRIPT"

# Case 5: Unmetered (2) + Limited Connectivity (3) -> Block (1)
create_mock_busctl 2 3
assert_exit_code "Limited connectivity (3) should block updates" 1 bash "$TARGET_SCRIPT"

# Case 6: Unmetered (2) + Portal Connectivity (2) -> Block (1)
create_mock_busctl 2 2
assert_exit_code "Portal connectivity (2) should block updates" 1 bash "$TARGET_SCRIPT"

# Case 7: Unmetered (2) + No Connectivity (1) -> Block (1)
create_mock_busctl 2 1
assert_exit_code "No connectivity (1) should block updates" 1 bash "$TARGET_SCRIPT"

# Case 8: Corrupt busctl output -> Block (1)
cat <<EOF > "$MOCK_BIN/busctl"
#!/bin/bash
echo "invalid output format"
exit 0
EOF
chmod +x "$MOCK_BIN/busctl"
assert_exit_code "Invalid busctl output should safely block updates" 1 bash "$TARGET_SCRIPT"

# Case 9: busctl failure -> Block (1)
cat <<EOF > "$MOCK_BIN/busctl"
#!/bin/bash
exit 1
EOF
chmod +x "$MOCK_BIN/busctl"
assert_exit_code "busctl command failure should safely block updates" 1 bash "$TARGET_SCRIPT"

echo "network-guard: $PASS_COUNT passed, $FAIL_COUNT failed."
[ "$FAIL_COUNT" -eq 0 ]
