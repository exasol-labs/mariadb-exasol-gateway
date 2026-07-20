#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 MARIADB_SOURCE BUILD_DIR SDK_PREFIX [CMAKE_ARGUMENT ...]" >&2
    exit 2
}

[[ $# -ge 3 ]] || usage
MARIADB_SOURCE=$(realpath "$1")
BUILD_DIR=$(realpath -m "$2")
SDK_PREFIX=$(realpath "$3")
shift 3

[[ -f "$MARIADB_SOURCE/CMakeLists.txt" && -d "$MARIADB_SOURCE/storage" ]] || {
    echo "Not a MariaDB server source tree: $MARIADB_SOURCE" >&2
    exit 2
}
[[ -f "$SDK_PREFIX/include/sessiongw/c_api.h" ]] || {
    echo "Exasol Gateway SDK is not installed under: $SDK_PREFIX" >&2
    exit 2
}

REPOSITORY_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PLUGIN_DESTINATION="$MARIADB_SOURCE/storage/exasol_gw"
rm -rf "$PLUGIN_DESTINATION"
mkdir -p "$PLUGIN_DESTINATION"
cp -a "$REPOSITORY_ROOT/plugin/." "$PLUGIN_DESTINATION/"

cmake -S "$MARIADB_SOURCE" -B "$BUILD_DIR" \
    -DWITH_EXASOL_GW_STORAGE_ENGINE=ON \
    -DCMAKE_PREFIX_PATH="$SDK_PREFIX${CMAKE_PREFIX_PATH:+;$CMAKE_PREFIX_PATH}" \
    "$@"

echo "Configured Exasol Gateway storage engine in $BUILD_DIR"
