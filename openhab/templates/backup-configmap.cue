package templates

#BackupConfigMapBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_config.fullname)-backup-scripts"
		namespace: _config.namespace
		labels:    _config.metadata.labels
	}
	data: {
		"backup.sh": """
			#!/bin/sh
			set -e
			TIMESTAMP=$(date +%Y%m%d-%H%M%S)
			ARCHIVE_NAME="\(_config.backup.archivePrefix)-backup-${TIMESTAMP}.tar.gz"
			ARCHIVE_PATH="/tmp/${ARCHIVE_NAME}"

			echo "Starting openHAB backup..."
			mkdir -p /tmp/staging

			if [ -d /openhab/userdata ]; then
			  echo "Copying userdata..."
			  mkdir -p /tmp/staging/userdata
			  tar -cf - -C /openhab/userdata \\
			    --exclude='logs/*' \\
			    --exclude='tmp/*' \\
			    --exclude='cache/*' \\
			    . | tar -xf - -C /tmp/staging/userdata
			fi

			if [ -d /openhab/conf ]; then
			  echo "Copying conf..."
			  mkdir -p /tmp/staging/conf
			  tar -cf - -C /openhab/conf . | tar -xf - -C /tmp/staging/conf
			fi

			echo "Creating archive ${ARCHIVE_NAME}..."
			tar -czf "${ARCHIVE_PATH}" -C /tmp/staging .
			rm -rf /tmp/staging
			echo "Backup complete: ${ARCHIVE_PATH}"
			"""

		"upload.sh": """
			#!/bin/sh
			set -e
			ARCHIVE=$(ls /tmp/*.tar.gz 2>/dev/null | head -n1)
			if [ -z "$ARCHIVE" ]; then
			  echo "ERROR: No backup archive found in /tmp"
			  exit 1
			fi

			echo "Configuring MinIO client..."
			mc alias set target "$S3_ENDPOINT" "$S3_ACCESS_KEY" "$S3_SECRET_KEY"

			DEST_PATH="target/${S3_BUCKET}"
			if [ -n "$S3_PREFIX" ]; then
			  DEST_PATH="${DEST_PATH}/${S3_PREFIX}"
			fi

			echo "Uploading $(basename "$ARCHIVE") to ${DEST_PATH}/..."
			mc cp "$ARCHIVE" "${DEST_PATH}/$(basename "$ARCHIVE")"
			echo "Upload complete."
			"""
	}
}
