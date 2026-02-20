#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[1/4] Shell syntax checks"
git ls-files "*.sh" | while IFS= read -r script_file; do
  [ -n "$script_file" ] || continue
  shebang="$(head -n 1 "$script_file" || true)"

  case "$shebang" in
    '#!'*bash*)
      bash -n "$script_file"
      ;;
    '#!'*sh*)
      sh -n "$script_file"
      ;;
    *)
      # Default to bash for project scripts without explicit shebang.
      bash -n "$script_file"
      ;;
  esac
done

echo "[2/4] Linux config and recipe structure checks"
python3 - <<'PY'
import configparser
import pathlib
import re
import sys
import tomllib
import xml.etree.ElementTree as ET

root = pathlib.Path(".")
errors = []


def add_error(path: pathlib.Path, line: int | None, message: str) -> None:
    where = f"{path}:{line}" if line else str(path)
    errors.append(f"{where}: {message}")


def validate_recipes() -> None:
    recipes_dir = root / "recipes"
    for recipe in sorted(recipes_dir.glob("*.yml")):
        lines = recipe.read_text(encoding="utf-8", errors="replace").splitlines()
        initramfs_line = None
        signing_line = None

        for idx, line in enumerate(lines, 1):
            from_file = re.match(r"^\s*-\s*from-file:\s*(\S+)\s*$", line)
            if from_file:
                target = recipe.parent / from_file.group(1)
                if not target.exists():
                    add_error(recipe, idx, f"from-file not found: {target}")

            source = re.match(r"^\s*source:\s*(\S+)\s*$", line)
            if source:
                target = root / "files" / source.group(1)
                if not target.exists():
                    add_error(recipe, idx, f"source not found under files/: {target}")

            if re.match(r"^\s*-\s*type:\s*initramfs\s*$", line):
                initramfs_line = idx
            if re.match(r"^\s*-\s*type:\s*signing\s*$", line):
                signing_line = idx

        if recipe.name.startswith("recipe-"):
            if initramfs_line is None:
                add_error(recipe, None, "missing '- type: initramfs'")
            if signing_line is None:
                add_error(recipe, None, "missing '- type: signing'")
            if initramfs_line and signing_line and signing_line < initramfs_line:
                add_error(recipe, signing_line, "'signing' should come after 'initramfs'")


def validate_ini_like_files() -> None:
    targets = []
    for file_path in root.joinpath("files/system").rglob("*"):
        if not file_path.is_file():
            continue

        path_str = str(file_path)
        if path_str.endswith(".service") or path_str.endswith(".timer"):
            targets.append(file_path)
            continue
        if "/etc/systemd/resolved.conf.d/" in path_str:
            targets.append(file_path)
            continue
        if "/usr/lib/NetworkManager/conf.d/" in path_str:
            targets.append(file_path)
            continue
        if "/usr/lib/rpm-ostreed.conf.d/" in path_str:
            targets.append(file_path)
            continue
        if "/usr/lib/ostree/" in path_str and path_str.endswith(".conf"):
            targets.append(file_path)
            continue
        if "/usr/lib/systemd/zram-generator.conf.d/" in path_str:
            targets.append(file_path)
            continue
        if "/usr/lib/systemd/system/" in path_str and path_str.endswith(".conf"):
            targets.append(file_path)
            continue

    for file_path in targets:
        parser = configparser.ConfigParser(strict=False)
        content = file_path.read_text(encoding="utf-8", errors="replace")
        try:
            parser.read_string(content)
        except Exception as exc:
            add_error(file_path, None, f"invalid ini-like syntax: {exc}")


def validate_toml_files() -> None:
    for file_path in root.joinpath("files/system").rglob("*.toml"):
        try:
            tomllib.loads(file_path.read_text(encoding="utf-8"))
        except Exception as exc:
            add_error(file_path, None, f"invalid toml: {exc}")


def validate_xml_files() -> None:
    for file_path in root.joinpath("files/system").rglob("*"):
        if not file_path.is_file():
            continue

        looks_like_xml = file_path.suffix == ".xml"
        if not looks_like_xml:
            head = file_path.read_text(encoding="utf-8", errors="replace").lstrip()
            looks_like_xml = head.startswith("<?xml")
        if not looks_like_xml:
            continue

        try:
            ET.fromstring(file_path.read_text(encoding="utf-8", errors="replace"))
        except Exception as exc:
            add_error(file_path, None, f"invalid xml: {exc}")


def validate_security_baseline() -> None:
    resolved_conf = root / "files/system/etc/systemd/resolved.conf.d/60-dns-overrides.conf"
    parser = configparser.ConfigParser(strict=False)
    parser.read_string(resolved_conf.read_text(encoding="utf-8", errors="replace"))

    dns_over_tls = parser.get("Resolve", "DNSOverTLS", fallback="").strip().lower()
    dnssec = parser.get("Resolve", "DNSSEC", fallback="").strip().lower()
    if dns_over_tls != "yes":
        add_error(resolved_conf, None, "DNSOverTLS must be 'yes' (strict baseline)")
    if dnssec != "yes":
        add_error(resolved_conf, None, "DNSSEC must be 'yes' (strict baseline)")

    sysctl_file = root / "files/system/usr/lib/sysctl.d/60-kernel-tuning.conf"
    sysctl_text = sysctl_file.read_text(encoding="utf-8", errors="replace")
    required_sysctl = [
        "net.ipv4.conf.all.accept_redirects = 0",
        "net.ipv4.conf.default.accept_redirects = 0",
        "net.ipv6.conf.all.accept_redirects = 0",
        "net.ipv6.conf.default.accept_redirects = 0",
        "net.ipv4.conf.all.send_redirects = 0",
        "net.ipv4.conf.default.send_redirects = 0",
    ]
    for key in required_sysctl:
        if key not in sysctl_text:
            add_error(sysctl_file, None, f"missing security sysctl: {key}")


validate_recipes()
validate_ini_like_files()
validate_toml_files()
validate_xml_files()
validate_security_baseline()

if errors:
    print("Validation failed:")
    for err in errors:
        print(f"- {err}")
    sys.exit(1)

print("All structure/config checks passed.")
PY

echo "[3/4] XML well-formedness (xmllint when available)"
if command -v xmllint >/dev/null 2>&1; then
  xmllint --noout files/system/usr/share/fontconfig/conf.d/60-font-rendering.conf
fi

echo "[4/4] Validation finished successfully"
