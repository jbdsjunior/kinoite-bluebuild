#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

failures=0
checks=0

ok() {
  printf '[OK] %s\n' "$1"
}

warn() {
  printf '[WARN] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  failures=$((failures + 1))
}

check_recipe_references() {
  checks=$((checks + 1))
  local missing=0

  while IFS=: read -r _ _ line; do
    [ -n "$line" ] || continue
    ref="$(printf '%s\n' "$line" | sed -E 's/.*from-file:[[:space:]]*([^[:space:]#]+).*/\1/')"
    [ -n "$ref" ] || continue
    if [ ! -f "recipes/$ref" ]; then
      printf '  missing recipe include: recipes/%s\n' "$ref"
      missing=1
    fi
  done < <(rg -n 'from-file:[[:space:]]*[^[:space:]#]+' recipes/*.yml || true)

  while IFS=: read -r _ _ line; do
    [ -n "$line" ] || continue
    ref="$(printf '%s\n' "$line" | sed -E 's/.*source:[[:space:]]*([^[:space:]#]+).*/\1/')"
    [ -n "$ref" ] || continue
    if [ ! -e "files/$ref" ]; then
      printf '  missing files source: files/%s\n' "$ref"
      missing=1
    fi
  done < <(rg -n 'source:[[:space:]]*[^[:space:]#]+' recipes/*.yml || true)

  if [ "$missing" -eq 0 ]; then
    ok "BlueBuild references (from-file/source)"
  else
    fail "BlueBuild references (from-file/source)"
  fi
}

check_shell_syntax() {
  checks=$((checks + 1))
  local missing=0
  local file

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    if ! bash -n "$file"; then
      printf '  bash syntax error: %s\n' "$file"
      missing=1
    fi
  done < <(find files scripts -type f -name '*.sh' 2>/dev/null || true)

  if [ "$missing" -eq 0 ]; then
    ok "Shell script syntax"
  else
    fail "Shell script syntax"
  fi
}

check_xml_syntax() {
  checks=$((checks + 1))
  local missing=0
  local file

  if ! command -v xmllint >/dev/null 2>&1; then
    warn "xmllint not available; skipping XML validation"
    return 0
  fi

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    if ! xmllint --noout "$file"; then
      printf '  xml syntax error: %s\n' "$file"
      missing=1
    fi
  done < <(rg -l '^[[:space:]]*<\?xml' files || true)

  if [ "$missing" -eq 0 ]; then
    ok "XML syntax"
  else
    fail "XML syntax"
  fi
}

check_toml_syntax() {
  checks=$((checks + 1))
  local missing=0
  local file

  if ! command -v python3 >/dev/null 2>&1; then
    warn "python3 not available; skipping TOML validation"
    return 0
  fi

  if ! python3 -c 'import tomllib' >/dev/null 2>&1; then
    warn "python3 tomllib not available; skipping TOML validation"
    return 0
  fi

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    if ! python3 -c 'import pathlib,sys,tomllib; tomllib.loads(pathlib.Path(sys.argv[1]).read_text())' "$file" >/dev/null 2>&1; then
      printf '  toml syntax error: %s\n' "$file"
      missing=1
    fi
  done < <(find files -type f -name '*.toml' 2>/dev/null || true)

  if [ "$missing" -eq 0 ]; then
    ok "TOML syntax"
  else
    fail "TOML syntax"
  fi
}

check_systemd_units() {
  checks=$((checks + 1))
  local missing=0
  local file

  if ! command -v systemd-analyze >/dev/null 2>&1; then
    warn "systemd-analyze not available; skipping unit verification"
    return 0
  fi

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    if ! systemd-analyze verify "$file" >/dev/null 2>&1; then
      printf '  systemd unit issue: %s\n' "$file"
      missing=1
    fi
  done < <(find files/system/usr/lib/systemd -type f \( -name '*.service' -o -name '*.timer' \) 2>/dev/null || true)

  if [ "$missing" -eq 0 ]; then
    ok "Systemd units"
  else
    fail "Systemd units"
  fi
}

check_optional_tools() {
  checks=$((checks + 1))
  if command -v yamllint >/dev/null 2>&1; then
    if yamllint .; then
      ok "yamllint"
    else
      fail "yamllint"
    fi
  else
    warn "yamllint not available; skipping YAML style checks"
  fi
}

check_recipe_references
check_shell_syntax
check_toml_syntax
check_xml_syntax
check_systemd_units
check_optional_tools

printf '\nSummary: %d checks, %d failures\n' "$checks" "$failures"

if [ "$failures" -ne 0 ]; then
  exit 1
fi
