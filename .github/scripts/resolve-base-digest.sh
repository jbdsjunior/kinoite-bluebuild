#!/usr/bin/env bash
# Resolve the upstream base image reference/digest declared by a BlueBuild recipe.
#
# Usage:
#   resolve-base-digest.sh [--image-only] <recipe.yml>
#
#   --image-only   Print only "<base-image>:<image-version>" (no network access).
#
# Requires skopeo for digest resolution. Uses yq when available and falls back
# to a minimal YAML scan (top-level scalar keys) otherwise.
set -euo pipefail

usage() {
    sed -n '2,10p' "$0" | sed -e 's/^# \{0,1\}//'
}

IMAGE_ONLY=0
RECIPE=""

for arg in "$@"; do
    case "$arg" in
        --image-only)
            IMAGE_ONLY=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo "ERROR: unknown option '$arg'" >&2
            usage >&2
            exit 2
            ;;
        *)
            if [[ -n "$RECIPE" ]]; then
                echo "ERROR: only one recipe path may be provided" >&2
                exit 2
            fi
            RECIPE="$arg"
            ;;
    esac
done

if [[ -z "$RECIPE" ]]; then
    echo "ERROR: recipe path required" >&2
    usage >&2
    exit 2
fi

if [[ ! -f "$RECIPE" ]]; then
    echo "ERROR: recipe not found: $RECIPE" >&2
    exit 1
fi

read_field() {
    local key="$1"

    if command -v yq >/dev/null 2>&1; then
        yq -r --arg key "$key" '.[$key] // ""' "$RECIPE"
        return 0
    fi

    # Minimal fallback: first top-level "<key>: value" line, inline comment stripped.
    sed -n "s/^${key}:[[:space:]]*//p" "$RECIPE" | head -n 1 |
        sed -e 's/[[:space:]]#.*$//' -e "s/^[\"']//" -e "s/[\"'][[:space:]]*\$//"
}

BASE_IMAGE="$(read_field base-image)"
IMAGE_VERSION="$(read_field image-version)"

if [[ -z "$BASE_IMAGE" || -z "$IMAGE_VERSION" ]]; then
    echo "ERROR: could not resolve 'base-image'/'image-version' from $RECIPE" >&2
    exit 1
fi

FULL_IMAGE="${BASE_IMAGE}:${IMAGE_VERSION}"

if [[ "$IMAGE_ONLY" -eq 1 ]]; then
    echo "$FULL_IMAGE"
    exit 0
fi

if ! command -v skopeo >/dev/null 2>&1; then
    echo "ERROR: skopeo is required to resolve image digests" >&2
    exit 1
fi

echo "Resolving digest for ${FULL_IMAGE}" >&2
skopeo inspect "docker://${FULL_IMAGE}" --format '{{.Digest}}'
