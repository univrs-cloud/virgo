#!/bin/bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/scripts/build-config.sh"
load_build_config "$@"
[[ -d "$WORK_DIR" ]] || exit 0
cd "$WORK_DIR"
[[ -f .virgo-live-build ]] || { echo "Not a virgoOS live-build directory: $WORK_DIR" >&2; exit 1; }
if [[ -d .build || -d chroot ]]; then
    [[ "$EUID" == 0 ]] || { echo "Run clean.sh as root." >&2; exit 1; }
    lb clean --all
fi
rm -rf config
echo "Cleaned $WORK_DIR; package cache retained."
