#!/bin/sh
set -eu
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
archive="/backup/out/{{ .backup.archivePrefix }}-mongodb-${timestamp}.gz"
mkdir -p /backup/out
mongodump ${MONGODUMP_EXTRA_ARGS:-} \
  --uri="${MONGODB_URI}" \
  --archive="${archive}" \
  --gzip
printf "%s" "${archive}" > /backup/out/backup-file
