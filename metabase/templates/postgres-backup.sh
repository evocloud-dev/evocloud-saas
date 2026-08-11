#!/bin/sh
set -eu
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
archive="/backup/out/{{ .backup.archivePrefix }}-postgresql-${timestamp}.sql.gz"
mkdir -p /backup/out
export PGPASSWORD="${DB_PASSWORD}"
pg_dump ${PG_DUMP_EXTRA_ARGS:-} \
  --host="${DB_HOST}" \
  --port="${DB_PORT}" \
  --username="${DB_USERNAME}" \
  --dbname="${DB_NAME}" | gzip -c > "${archive}"
printf "%s" "${archive}" > /backup/out/backup-file
