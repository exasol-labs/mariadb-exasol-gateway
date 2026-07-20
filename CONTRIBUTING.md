# Contributing

- Build against a clean supported MariaDB source checkout and an installed
  Exasol Gateway SDK release.
- Keep the adapter on the stable `sessiongw_c_*` C ABI; do not add Exasol
  server-private or Arrow C++ dependencies.
- Preserve `ENGINE=EXASOL`, transaction lifecycles, strict conversion, and
  fail-closed identity behavior.
- Add tests for malformed remote data and MariaDB callback lifecycle changes.

Contributions are licensed under GPL-2.0-only.
