#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 BUILD_DIR [JOBS]" >&2
    exit 2
fi

BUILD_DIR=$1
JOBS=${2:-$(getconf _NPROCESSORS_ONLN)}
cmake --build "$BUILD_DIR" --target exasol_gw --parallel "$JOBS"
