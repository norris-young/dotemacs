#!/usr/bin/env bash
# End-to-end verification of a built bundle in an isolated HOME.
# Usage: verify.sh path/to/bundle.tar.xz [--no-clangd]
set -euo pipefail

BUNDLE_TAR=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
shift || true
EXTRA_ARGS=("$@")

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/home" "$TMP/src"

echo "[verify] extracting bundle"
tar -xf "$BUNDLE_TAR" -C "$TMP/src"
BUNDLE=$TMP/src/$(ls "$TMP/src" | head -1)

echo "[verify] installing into $TMP/home (this takes a while)"
HOME="$TMP/home" "$BUNDLE/install.sh" --yes "${EXTRA_ARGS[@]}" \
    || { echo "[verify] install failed"; exit 1; }

echo "[verify] checking launcher"
HOME="$TMP/home" "$TMP/home/.local/bin/emacs" --version | head -1 | grep -q '31\.1' \
    || { echo "[verify] emacs version mismatch"; exit 1; }

echo "[verify] OK"
