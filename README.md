# Exasol Gateway Storage Engine for MariaDB

Open-source MariaDB storage engine exposing Exasol tables through the public
[Exasol Gateway SDK](https://github.com/exasol-labs/exasol-gateway-sdk).
MariaDB SQL keeps the stable engine name:

```sql
CREATE TABLE example (...) ENGINE=EXASOL;
```

> **Status:** `0.x` preview. The initial supported server line is MariaDB 11.4
> LTS. A plugin binary must be built and packaged for the exact supported
> MariaDB server ABI; compatibility across server versions is not assumed.

## Source boundaries

This repository is the canonical plugin source. It does not vendor or fork the
MariaDB server. The build helper copies `plugin/` into a clean MariaDB source
tree, where MariaDB's `MYSQL_ADD_PLUGIN` infrastructure builds
`ha_exasol_gw.so`.

The plugin consumes only the SDK's stable `sessiongw_c_*` C ABI through
`ExasolGateway::C`. It does not include Arrow C++ or Exasol server-private
headers.

## Build

Install Exasol Gateway SDK first, then obtain a clean MariaDB source checkout:

```sh
git clone https://github.com/MariaDB/server.git mariadb
git -C mariadb checkout mariadb-11.4.9

./tools/configure_mariadb.sh \
    "$PWD/mariadb" "$PWD/build-mariadb" "$PWD/sdk-install" \
    -DCMAKE_BUILD_TYPE=Release
./tools/build_plugin.sh "$PWD/build-mariadb"
```

The resulting module is under:

```text
build-mariadb/storage/exasol_gw/ha_exasol_gw.so
```

## Runtime configuration

The service-account model is fail-closed and requires explicit settings,
including:

```text
EXASOL_SESSIONGW_HOST
EXASOL_SESSIONGW_PORT
EXASOL_SESSIONGW_USER
EXASOL_SESSIONGW_PASSWORD
EXASOL_SESSIONGW_TLS=verify
EXASOL_SESSIONGW_CA_FILE
EXASOL_SESSIONGW_IDENTITY_MODE=service_account
EXASOL_SESSIONGW_ALLOWED_MARIADB_USERS=<allowlist>
```

Production deployments must use verified TLS. `plain` and `skip_verify` exist
only for isolated tests. See [identity and audit mapping](docs/identity.md) and
[transaction semantics](docs/transactions.md).

## Testing

Public CI builds the plugin against a clean pinned MariaDB checkout and an
installed public SDK. The integration workload under `plugin/test/` additionally
requires an Exasol/Nano server harness and is run by the protected internal
end-to-end gate.

## License

GPL-2.0-only; see [LICENSE](LICENSE). The separately distributed SDK is MIT.
See [NOTICE](NOTICE) for dependency information.
