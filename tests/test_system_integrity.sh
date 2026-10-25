#!/usr/bin/env bash
# Unit and integration test for system integrity, syntax, and documentation
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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

echo "Running system integrity and syntax tests..."

# 1. Shell script syntax validation (bash -n)
for sh_file in "$PROJECT_ROOT"/files/system/usr/bin/* "$PROJECT_ROOT"/files/system/etc/profile.d/*.sh "$PROJECT_ROOT"/tests/*.sh; do
    if [ -f "$sh_file" ]; then
        rel_path="${sh_file#$PROJECT_ROOT/}"
        assert_true "Shell syntax: $rel_path" "bash -n '$sh_file'"
    fi
done

# 2. Sysctl syntax validation
python3 - <<EOF
import glob, sys, os

root = '$PROJECT_ROOT'
sysctl_files = glob.glob(os.path.join(root, 'files/system/usr/lib/sysctl.d/*.conf'))
for sf in sorted(sysctl_files):
    rel = os.path.relpath(sf, root)
    with open(sf, 'r') as f:
        for idx, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith('#') or line.startswith(';'):
                continue
            if '=' not in line:
                print(f"Invalid sysctl line {idx} in {rel}: {line}", file=sys.stderr)
                sys.exit(1)
            k, v = [x.strip() for x in line.split('=', 1)]
            if not k or not v:
                print(f"Empty key or value at {idx} in {rel}", file=sys.stderr)
                sys.exit(1)
EOF
assert_true "Sysctl key=value syntax in files/system/usr/lib/sysctl.d/" "[ $? -eq 0 ]"

# 3. Tmpfiles.d type validation
python3 - <<EOF
import glob, sys, os

root = '$PROJECT_ROOT'
valid_types = {'f', 'F', 'w', 'd', 'D', 'e', 'v', 'q', 'Q', 'p', 'p+', 'L', 'L+', 'c', 'c+', 'b', 'b+', 'C', 'C+', 'x', 'X', 'r', 'R', 'z', 'Z', 't', 'T', 'h', 'H', 'a', 'a+'}
tmpfiles = glob.glob(os.path.join(root, 'files/**/*.conf'), recursive=True)
tmpfiles = [f for f in tmpfiles if 'tmpfiles.d' in f]

for tf in sorted(tmpfiles):
    rel = os.path.relpath(tf, root)
    with open(tf, 'r') as f:
        for idx, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split()
            if len(parts) < 2 or parts[0] not in valid_types:
                print(f"Invalid tmpfile directive at {rel}:{idx}: {line}", file=sys.stderr)
                sys.exit(1)
EOF
assert_true "Tmpfiles directive syntax across tmpfiles.d" "[ $? -eq 0 ]"

# 4. Zero trailing whitespace check across tracked repository files
python3 - <<EOF
import os, sys

root = '$PROJECT_ROOT'
os.chdir(root)
files = os.popen('git ls-files').read().splitlines()
for f in files:
    if os.path.islink(f) or not os.path.isfile(f):
        continue
    try:
        with open(f, 'r', encoding='utf-8') as fh:
            for idx, line in enumerate(fh, 1):
                if line.rstrip('\r\n') != line.rstrip():
                    print(f"Trailing whitespace in {f}:{idx}", file=sys.stderr)
                    sys.exit(1)
    except UnicodeDecodeError:
        pass
EOF
assert_true "Zero trailing whitespace across all tracked repository files" "[ $? -eq 0 ]"

# 5. Documentation internal links validation
python3 - <<EOF
import re, os, sys

root = '$PROJECT_ROOT'
for doc in ['AGENTS.md', 'README.md', 'docs/POST_INSTALL.md']:
    doc_path = os.path.join(root, doc)
    with open(doc_path, 'r', encoding='utf-8') as f:
        content = f.read()
    links = re.findall(r'\[([^\]]+)\]\(([^)]+)\)', content)
    doc_dir = os.path.dirname(doc_path)
    for text, link in links:
        if link.startswith('http') or link.startswith('#') or link.startswith('mailto:'):
            continue
        path = link.split('#')[0]
        if not path:
            continue
        target = os.path.normpath(os.path.join(doc_dir, path))
        if not os.path.exists(target):
            print(f"Broken link in {doc}: {link} -> {target}", file=sys.stderr)
            sys.exit(1)
EOF
assert_true "Markdown relative links in AGENTS.md, README.md, POST_INSTALL.md" "[ $? -eq 0 ]"

echo "system_integrity: $PASS_COUNT passed, $FAIL_COUNT failed."
if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
exit 0
