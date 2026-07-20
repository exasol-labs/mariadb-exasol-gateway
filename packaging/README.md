# Packaging Boundary

A plugin package is specific to an explicitly tested MariaDB server release and
requires the separately installed Exasol Gateway SDK SONAME recorded in its
manifest. The package does not bundle MariaDB, the SDK, Arrow, OpenSSL, or
credentials.

`tools/package_plugin.sh` rejects binaries containing build-tree RPATH/RUNPATH
entries and creates a reproducible tar archive containing:

```text
lib/mariadb/plugin/ha_exasol_gw.so
MANIFEST.txt
LICENSE
NOTICE
README.md
```

Distribution-specific RPM/DEB metadata may wrap this archive, but must depend on
the exact supported MariaDB server ABI and `libSessionGatewaySdk.so.0`, retain
all dependency notices, and configure the system loader without embedding build
paths.
