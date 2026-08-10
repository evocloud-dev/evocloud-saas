#!/bin/sh
set -eu
archive="$(cat /backup/out/backup-file)"
target="backup/{{ .backup.s3.bucket }}"
if [ -n "${S3_PREFIX:-}" ]; then
	target="${target}/${S3_PREFIX}"
fi
mc alias set backup "${S3_ENDPOINT}" "${S3_ACCESS_KEY}" "${S3_SECRET_KEY}"
if [ "${S3_CREATE_BUCKET_IF_NOT_EXISTS}" = "true" ]; then
	mc mb --ignore-existing "backup/${S3_BUCKET}"
fi
mc cp "${archive}" "${target}/"
