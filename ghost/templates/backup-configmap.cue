package templates

import corev1 "k8s.io/api/core/v1"

#BackupConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.#serviceName)-backup-scripts"
		namespace: #config.metadata.namespace
		labels:    #config.labels
	}
	data: {
		"content-backup.sh": """
			#!/bin/sh
			set -e
			TIMESTAMP=$(date +%Y%m%d-%H%M%S)
			ARCHIVE="/backup/\(#config.backup.archivePrefix)-${TIMESTAMP}.tar.gz"
			echo "Creating Ghost content backup archive..."
			tar -czf "${ARCHIVE}" -C /var/lib/ghost/content .
			echo "Archive created: ${ARCHIVE}"
			"""
		"upload-backup.sh": string
		if #config.backup.s3.createBucketIfNotExists {
			"upload-backup.sh": """
				#!/bin/sh
				set -e
				ARCHIVE=$(ls -t /backup/*.gz 2>/dev/null | head -1)
				if [ -z "${ARCHIVE}" ]; then
				  echo "No backup archive found"; exit 1
				fi
				mc alias set s3 "${S3_ENDPOINT}" "${S3_ACCESS_KEY}" "${S3_SECRET_KEY}"
				mc mb --ignore-existing "s3/${S3_BUCKET}"
				mc cp "${ARCHIVE}" "s3/${S3_BUCKET}/${S3_PREFIX}/$(basename "${ARCHIVE}")"
				echo "Upload complete: $(basename "${ARCHIVE}")"
				"""
		}
		if !#config.backup.s3.createBucketIfNotExists {
			"upload-backup.sh": """
				#!/bin/sh
				set -e
				ARCHIVE=$(ls -t /backup/*.gz 2>/dev/null | head -1)
				if [ -z "${ARCHIVE}" ]; then
				  echo "No backup archive found"; exit 1
				fi
				mc alias set s3 "${S3_ENDPOINT}" "${S3_ACCESS_KEY}" "${S3_SECRET_KEY}"
				mc cp "${ARCHIVE}" "s3/${S3_BUCKET}/${S3_PREFIX}/$(basename "${ARCHIVE}")"
				echo "Upload complete: $(basename "${ARCHIVE}")"
				"""
		}
	}
}