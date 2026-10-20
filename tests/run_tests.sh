#!/usr/bin/env bash
# Test Runner for all unit tests
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo " Running Kinoite BlueBuild Test Suite"
echo "========================================"

FAILED=0

for test_file in "$SCRIPT_DIR"/test_*.sh; do
    echo ""
    echo ">> Executing: $(basename "$test_file")"
    if bash "$test_file"; then
        echo ">> [PASS] $(basename "$test_file")"
    else
        echo ">> [FAIL] $(basename "$test_file")"
        FAILED=1
    fi
done

echo ""
echo "========================================"
if [ "$FAILED" -eq 0 ]; then
    echo " ALL TESTS PASSED SUCCESSFULLY!"
    echo "========================================"
    exit 0
else
    echo " SOME TESTS FAILED!"
    echo "========================================"
    exit 1
fi
