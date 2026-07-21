# Install a released MariaDB plugin package

## Supported release target

The initial release artifact is deliberately narrow:

| Property | Supported value |
|---|---|
| Operating system | Ubuntu 24.04 amd64 |
| MariaDB server | 11.4.9 build compatible with the release artifact |
| Plugin ABI | `ha_exasol_gw.so` built by the release workflow |
| Gateway protocol | SessionGateway v1 |

Do not install an artifact on another MariaDB version, operating system, CPU
architecture, or vendor build. MariaDB storage-engine binary compatibility is
not assumed outside the manifest's exact target.

## Download and verify

Download both the `.tar.gz` artifact and its `.sha256` file from the matching
GitHub Release, then verify the archive before extracting it:

```sh
sha256sum --check mariadb-exasol-gateway-*.tar.gz.sha256
tar -xzf mariadb-exasol-gateway-*.tar.gz
cd mariadb-exasol-gateway-*
cat MANIFEST.txt
```

The manifest must match the running server's supported MariaDB version,
platform, and architecture.

## Install

The archive stages the plugin together with the required Exasol Gateway SDK and
Arrow C++ runtime. Copy **all** shared libraries from its plugin directory;
do not copy only `ha_exasol_gw.so` and do not install PyArrow.

```sh
plugin_dir=$(mariadbd --verbose --help 2>/dev/null |
  awk '$1 == "plugin-dir" { print $2; exit }')
test -n "$plugin_dir"
sudo install -d "$plugin_dir"
sudo install -m 0755 lib/mariadb/plugin/* "$plugin_dir/"
sudo systemctl restart mariadb
```

The package uses only the relocatable loader path `$ORIGIN`; the three bundled
libraries must remain together in MariaDB's plugin directory. The normal
Ubuntu base runtime remains an operating-system prerequisite.

Verify that MariaDB can load the plugin:

```sql
INSTALL SONAME 'ha_exasol_gw.so';
SHOW ENGINES;
```

`EXASOL` must appear in `SHOW ENGINES`. If loading fails, remove the copied
files and use an artifact matching the exact server target instead of trying to
substitute libraries from a developer installation.

## Configure the gateway

Before creating an `ENGINE=EXASOL` table, configure the MariaDB service
account with verified TLS:

```text
EXASOL_SESSIONGW_HOST
EXASOL_SESSIONGW_PORT
EXASOL_SESSIONGW_USER
EXASOL_SESSIONGW_PASSWORD
EXASOL_SESSIONGW_TLS=verify
EXASOL_SESSIONGW_CA_FILE
EXASOL_SESSIONGW_IDENTITY_MODE=service_account
EXASOL_SESSIONGW_ALLOWED_MARIADB_USERS
```

See [identity and audit mapping](identity.md) and
[transaction semantics](transactions.md). Secrets belong in the service
manager's protected environment or secret store, not in SQL or the package.

## Upgrade and rollback

1. Stop MariaDB or place it in maintenance mode.
2. Verify and extract the new matching package.
3. Replace all files from `lib/mariadb/plugin/` as one set.
4. Start MariaDB and check `SHOW ENGINES`.
5. Keep the previous verified archive until the Gateway workload is confirmed.

To roll back, stop MariaDB, restore all three files from the prior matching
package, and start MariaDB. Never combine plugin, SDK, or Arrow files from
different package versions.
