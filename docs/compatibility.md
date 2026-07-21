# Compatibility and Versioning

## Initial matrix

| Plugin line | MariaDB source line | Exasol Gateway SDK | Protocol |
|---|---|---|---|
| `0.1.x` preview | `11.4.x` LTS (CI baseline `11.4.9`) | CI pin `v0.1.0-alpha.1` / `libSessionGatewaySdk.so.0` | SessionGateway v1 with negotiated capabilities |

MariaDB storage-engine APIs and binary layouts are not stable across arbitrary
server releases. Build and package `ha_exasol_gw.so` for the exact MariaDB
version named in `MANIFEST.txt`. Never copy a plugin binary between untested
server versions.

The plugin uses only the SDK's stable C ABI. SDK capability negotiation, not the
SDK version string, decides whether optional native read/write and transaction
features are available from a server.

## Supported MariaDB Type Matrix

The adapter validates remote schema metadata before read or mutation and rejects
unsupported local DDL before creating a remote table. It supports the following
MariaDB definitions symmetrically for DDL, reads, and native writes:

| MariaDB type | Exasol representation | Limits / notes |
|---|---|---|
| `BIT(1)` | `BOOLEAN` | Wider `BIT` values are rejected. |
| Signed integer types and `YEAR` | `DECIMAL(p,0)` | Exact range-preserving precision. |
| `TINYINT`, `SMALLINT`, `MEDIUMINT`, and `INT` `UNSIGNED` | `DECIMAL(p,0)` | Exact range-preserving precision. |
| Signed `BIGINT` | `DECIMAL(19,0)` | Boundary values round-trip. |
| `DECIMAL` / `NUMERIC` | `DECIMAL(p,s)` | `1 <= p <= 36` and `0 <= s <= p`. |
| `FLOAT` / `DOUBLE` | `DOUBLE PRECISION` | Subject to the normal floating-point representation. |
| `DATE` | `DATE` | Zero dates are rejected before mutation. |
| `DATETIME[(0..6)]` | `TIMESTAMP` | Timezone-free. |
| `TIMESTAMP[(0..6)]` | `TIMESTAMP WITH LOCAL TIME ZONE` | Converted through the MariaDB session timezone; ambiguous or out-of-range values are rejected before mutation. |
| `CHAR` / `VARCHAR` | UTF-8 `CHAR` / `VARCHAR` | Only the default non-binary `utf8mb4` collation is supported; length is measured in characters. |

`BIGINT UNSIGNED`, binary/non-UTF8 or non-default-collation strings, intervals,
spatial types, JSON, blobs, wider `BIT` values, unsupported table clauses, and
all other MariaDB types fail closed. No rejected DDL or value conversion may
create or partially mutate a remote Exasol table.

## Update process

1. Update the pinned SDK release in CI and run SDK unit/install consumers.
2. Build against a clean supported MariaDB tag.
3. Run the public mock/build boundary checks.
4. Run the protected live Exasol integration workload.
5. Update this matrix and package manifest before release.

The MariaDB fork is an integration/upstream vehicle, not the canonical plugin
source. Changes originate here and are copied into a clean MariaDB checkout by
the build helper.
