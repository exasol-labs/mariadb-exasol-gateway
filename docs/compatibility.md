# Compatibility and Versioning

## Initial matrix

| Plugin line | MariaDB source line | Exasol Gateway SDK | Protocol |
|---|---|---|---|
| `0.1.x` preview | `11.4.x` LTS (CI baseline `11.4.9`) | `0.1.x` / `libSessionGatewaySdk.so.0` | SessionGateway v1 with negotiated capabilities |

MariaDB storage-engine APIs and binary layouts are not stable across arbitrary
server releases. Build and package `ha_exasol_gw.so` for the exact MariaDB
version named in `MANIFEST.txt`. Never copy a plugin binary between untested
server versions.

The plugin uses only the SDK's stable C ABI. SDK capability negotiation, not the
SDK version string, decides whether optional native read/write and transaction
features are available from a server.

## Update process

1. Update the pinned SDK release in CI and run SDK unit/install consumers.
2. Build against a clean supported MariaDB tag.
3. Run the public mock/build boundary checks.
4. Run the protected live Exasol integration workload.
5. Update this matrix and package manifest before release.

The MariaDB fork is an integration/upstream vehicle, not the canonical plugin
source. Changes originate here and are copied into a clean MariaDB checkout by
the build helper.
