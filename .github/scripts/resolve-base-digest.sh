#!/usr/bin/env bash
# Resolve the upstream base image reference/digest declared by a BlueBuild recipe.
#
# Usage:
#   resolve-base-digest.sh [--image-only] <recipe.yml>
#
#   --image-only   Print only "<base-image>:<image-version>" (no network access).
#
# Reads the top-level `base-image` and `image-version` scalars directly, so it has
# no dependency on yq/jq (the runner's yq is mikefarah v4, which has no `--arg`).
# Requires skopeo only for digest resolution.
set -euo pipefail

usage() {
    sed -n '2,11p' "$0" | sed -e 's/^# \{0,1\}//'
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

# Extract a top-level scalar value, stripping inline comments and quotes.
read_field() {
    local key="$1"
    local line value

    line="$(grep -m1 "^${key}:" "$RECIPE" || true)"
    if [[ -z "$line" ]]; then
        return 0
    fi

    value="${line#*:}"
    value="${value%%[[:space:]]#*}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    value="${value#\"}"
    value="${value%\"}"
    value="${value#\'}"
    value="${value%\'}"

    printf '%s\n' "$value"
}

BASE_IMAGE="$(read_field base-image)"
IMAGE_VERSION="$(read_field image-version)"

if [[ -z "$BASE_IMAGE" || -z "$IMAGE_VERSION" ]]; then
    echo "ERROR: could not resolve 'base-image'/'image-version' from $RECIPE" >&2
    echo "       Expected top-level scalars, e.g.:" >&2
    echo "         base-image: quay.io/fedora/fedora-kinoite" >&2
    echo "         image-version: latest" >&2
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
