#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 5 ]]; then
    echo "Usage: $0 PLUGIN_SO OUTPUT_DIR PACKAGE_VERSION MARIADB_VERSION SDK_VERSION" >&2
    exit 2
fi

PLUGIN_SO=$(realpath "$1")
OUTPUT_DIR=$(realpath -m "$2")
PACKAGE_VERSION=$3
MARIADB_VERSION=$4
SDK_VERSION=$5
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

[[ -f "$PLUGIN_SO" ]] || { echo "Missing plugin: $PLUGIN_SO" >&2; exit 2; }
if readelf -d "$PLUGIN_SO" | grep -Eq '\((RPATH|RUNPATH)\)'; then
    echo "Plugin contains a non-relocatable RPATH/RUNPATH" >&2
    readelf -d "$PLUGIN_SO" >&2
    exit 1
fi

NAME="mariadb-exasol-gateway-${PACKAGE_VERSION}-mariadb-${MARIADB_VERSION}"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/$NAME/lib/mariadb/plugin" "$OUTPUT_DIR"
cp "$PLUGIN_SO" "$STAGE/$NAME/lib/mariadb/plugin/ha_exasol_gw.so"
cp "$ROOT/LICENSE" "$ROOT/NOTICE" "$ROOT/README.md" "$STAGE/$NAME/"
cat > "$STAGE/$NAME/MANIFEST.txt" <<EOF
package_version=$PACKAGE_VERSION
mariadb_version=$MARIADB_VERSION
exasol_gateway_sdk_version=$SDK_VERSION
sdk_soname=libSessionGatewaySdk.so.0
engine_name=EXASOL
EOF
tar --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 --numeric-owner \
    -C "$STAGE" -czf "$OUTPUT_DIR/$NAME.tar.gz" "$NAME"
sha256sum "$OUTPUT_DIR/$NAME.tar.gz" > "$OUTPUT_DIR/$NAME.tar.gz.sha256"
echo "$OUTPUT_DIR/$NAME.tar.gz"
