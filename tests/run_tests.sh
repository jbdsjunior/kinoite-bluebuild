#!/usr/bin/env bash
# Test Runner for all unit tests
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERBOSE="${VERBOSE:-0}"
[[ "${1:-}" == "-v" || "${1:-}" == "--verbose" ]] && VERBOSE=1

echo "========================================"
echo " Running Kinoite BlueBuild Test Suite"
echo "========================================"

FAILED=0

for test_file in "$SCRIPT_DIR"/test_*.sh; do
    tname="$(basename "$test_file")"
    if [ "$VERBOSE" -eq 1 ]; then
        echo ""
        echo ">> Executing: $tname"
        if bash "$test_file"; then
            echo ">> [PASS] $tname"
        else
            echo ">> [FAIL] $tname"
            FAILED=1
        fi
    else
        out=$(bash "$test_file" 2>&1) && res=0 || res=$?
        if [ "$res" -eq 0 ]; then
            summary=$(echo "$out" | grep -E "passed, [0-9]+ failed" | tail -n 1 || true)
            if [ -n "$summary" ]; then
                echo "  [PASS] $tname ($summary)"
            else
                echo "  [PASS] $tname"
            fi
        else
            echo "  [FAIL] $tname"
            echo "$out"
            FAILED=1
        fi
    fi
done

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
