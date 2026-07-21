#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 9 ]]; then
    echo "Usage: $0 PLUGIN_SO SDK_SO ARROW_SO OUTPUT_DIR PACKAGE_VERSION MARIADB_VERSION SDK_VERSION PLATFORM ARCH" >&2
    exit 2
fi

PLUGIN_SO=$(realpath "$1")
SDK_SO=$(realpath "$2")
ARROW_SO=$(realpath "$3")
OUTPUT_DIR=$(realpath -m "$4")
PACKAGE_VERSION=$5
MARIADB_VERSION=$6
SDK_VERSION=$7
PLATFORM=$8
ARCH=$9
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

for library in "$PLUGIN_SO" "$SDK_SO" "$ARROW_SO"; do
    [[ -f "$library" ]] || { echo "Missing library: $library" >&2; exit 2; }
done

rpath_of() {
    readelf -d "$1" | awk '/\((RPATH|RUNPATH)\)/ { print $NF }' | tr -d '[]'
}
require_origin_rpath() {
    local rpath
    rpath=$(rpath_of "$1")
    [[ "$rpath" == '$ORIGIN' ]] || {
        echo "Expected the relocatable RPATH \$ORIGIN in $1, got: ${rpath:-<none>}" >&2
        exit 1
    }
}

# The plugin's old-style DT_RPATH is deliberately $ORIGIN. Unlike DT_RUNPATH it
# also resolves dependencies of the SDK and Arrow runtime staged beside it.
require_origin_rpath "$PLUGIN_SO"
require_origin_rpath "$SDK_SO"

NAME="mariadb-exasol-gateway-${PACKAGE_VERSION}-mariadb-${MARIADB_VERSION}-${PLATFORM}-${ARCH}"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
PLUGIN_DIR="$STAGE/$NAME/lib/mariadb/plugin"
mkdir -p "$PLUGIN_DIR" "$OUTPUT_DIR"

copy_library() {
    local source=$1
    local resolved soname base
    resolved=$(realpath "$source")
    base=$(basename "$resolved")
    install -m 0755 "$resolved" "$PLUGIN_DIR/$base"
    soname=$(readelf -d "$resolved" | awk '/\(SONAME\)/ { print $NF }' | tr -d '[]')
    if [[ -n "$soname" && "$soname" != "$base" ]]; then
        ln -s "$base" "$PLUGIN_DIR/$soname"
    fi
}

copy_library "$PLUGIN_SO"
copy_library "$SDK_SO"
copy_library "$ARROW_SO"
cp "$ROOT/LICENSE" "$ROOT/NOTICE" "$ROOT/README.md" "$STAGE/$NAME/"
cp "$ROOT/docs/install.md" "$STAGE/$NAME/INSTALL.md"
cat > "$STAGE/$NAME/MANIFEST.txt" <<EOF
package_version=$PACKAGE_VERSION
mariadb_version=$MARIADB_VERSION
platform=$PLATFORM
architecture=$ARCH
exasol_gateway_sdk_version=$SDK_VERSION
sdk_soname=$(readelf -d "$SDK_SO" | awk '/\(SONAME\)/ { print $NF }' | tr -d '[]')
arrow_soname=$(readelf -d "$ARROW_SO" | awk '/\(SONAME\)/ { print $NF }' | tr -d '[]')
engine_name=EXASOL
install_layout=copy-all-files-under-lib/mariadb/plugin-to-the-server-plugin-directory
EOF

tar --sort=name --mtime='UTC 1970-01-01' --owner=0 --group=0 --numeric-owner \
    -C "$STAGE" -czf "$OUTPUT_DIR/$NAME.tar.gz" "$NAME"
sha256sum "$OUTPUT_DIR/$NAME.tar.gz" > "$OUTPUT_DIR/$NAME.tar.gz.sha256"
echo "$OUTPUT_DIR/$NAME.tar.gz"
