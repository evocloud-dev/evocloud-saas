# Metabase Timoni Module

A [timoni.sh](http://timoni.sh) module for deploying Metabase to Kubernetes clusters.


## Configuration

The Metabase module supports the following main configuration sections:

### 1. Metabase App Settings (`metabase`)
- `port`: The Jetty listener port inside the container (default: `3000`).
- `siteUrl`: The URL of the Metabase site.
- `aiFeaturesEnabled`: Toggle AI features (default: `false`).
- `encryptionSecretKey`: Base64 encoded encryption key. If empty, a default static value is used for non-production environments. Set `existingSecret` in production.
- `javaTimezone`: Timezone for Java runtime (default: `UTC`).

### 2. Database Backend (`database` / `postgresql`)
- **Internal PostgreSQL** (enabled by default):
  - Configured via `postgresql: enabled: true`.
  - Customize persistent storage size using `postgresql.standalone.persistence.size`.
  - Define custom SQL extensions using `postgresql.initdb.scripts`.
- **External PostgreSQL**:
  - Disable internal database via `postgresql: enabled: false`.
  - Configure connection details under `database.external` (e.g. `host`, `port`, `name`, `username`, `existingSecret`).

### 3. Automated S3 Backup (`backup`)
- `enabled`: Set to `true` to enable daily cron backups of the database.
- `schedule`: Cron expression for the backup Job (default: `0 3 * * *`).
- `s3`: Connection endpoint, bucket name, prefix, and credentials.

### 4. Integration Features (`gateway` / `externalSecrets`)
- `gateway`: Kubernetes Gateway API HTTPRoute definition for advanced routing.
- `externalSecrets`: External Secrets Operator integration for importing secret keys.
