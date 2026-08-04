package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"
)

#BackupScriptsConfigMap: timoniv1.#ImmutableConfig & {
	#config: #Config
	#Kind: timoniv1.#ConfigMapKind
	#Meta: #config.metadata & { name: #config.metadata.name + "-backup-scripts" }
	#Data: {
		"mongodb-backup.sh": """
		#!/bin/sh
		set -eu
		timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
		archive="/backup/out/\(#config.backup.archivePrefix)-mongodb-${timestamp}.gz"
		mkdir -p /backup/out
		mongodump ${MONGODUMP_EXTRA_ARGS:-} \\
		  --uri="${MONGODB_URI}" \\
		  --archive="${archive}" \\

		  --gzip
		printf "%s" "${archive}" > /backup/out/backup-file
		"""
		"upload-backup.sh": """
		#!/bin/sh
		set -eu
		archive="$(cat /backup/out/backup-file)"
		target="backup/\(#config.backup.s3.bucket)"
		if [ -n "${S3_PREFIX:-}" ]; then
			target="${target}/${S3_PREFIX}"
		fi
		mc alias set backup "${S3_ENDPOINT}" "${S3_ACCESS_KEY}" "${S3_SECRET_KEY}"
		if [ "${S3_CREATE_BUCKET_IF_NOT_EXISTS}" = "true" ]; then
			mc mb --ignore-existing "backup/${S3_BUCKET}"
		fi
		mc cp "${archive}" "${target}/"
		"""
	}
}
