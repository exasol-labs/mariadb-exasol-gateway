# Security Policy

Report suspected vulnerabilities privately to <security@exasol.com>. Do not
open public vulnerability issues.

Production deployments must use verified TLS, explicit service-account
credentials, and an explicit MariaDB authenticated-principal allowlist. The
plugin never falls back to a broader identity. Uncertain mutation/transaction
completion is reported and must not be replayed automatically.
