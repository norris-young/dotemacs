#!/usr/bin/env bash
# Remove a dotemacs offline installation.
#   ./uninstall.sh            remove launchers and the ~/.emacs.d symlink
#   ./uninstall.sh --purge    also remove the install prefix (~/.local/opt/dotemacs)
# Backups created by install.sh are never touched.

set -euo pipefail

BUNDLE_DIR=$(cd "$(dirname "$0")" && pwd)
PREFIX=${PREFIX:-$HOME/.local/opt/dotemacs}
EMACS_DIR=${EMACS_DIR:-$HOME/.emacs.d}
BIN_DIR=${BIN_DIR:-$HOME/.local/bin}
PURGE=0

while [ $# -gt 0 ]; do
    case "$1" in
        --purge) PURGE=1; shift ;;
        --prefix) PREFIX=$2; shift 2 ;;
        --emacs-dir) EMACS_DIR=$2; shift 2 ;;
        --bin-dir) BIN_DIR=$2; shift 2 ;;
        *) shift ;;
    esac
done

echo "[uninstall] removing launchers"
rm -f "$BIN_DIR/emacs" "$BIN_DIR/emacs31" "$BIN_DIR/emacsclient" "$BIN_DIR/dotemacs"

if [ -L "$EMACS_DIR" ]; then
    rm -f "$EMACS_DIR"
    echo "[uninstall] removed symlink $EMACS_DIR"
elif [ -d "$EMACS_DIR" ]; then
    echo "[uninstall] $EMACS_DIR is a real directory, leaving it alone"
fi

if [ "$PURGE" = 1 ]; then
    echo "[uninstall] removing $PREFIX"
    rm -rf "$PREFIX"
fi

echo "[uninstall] done (backups like ~/.emacs.d.bak.* are kept)"
