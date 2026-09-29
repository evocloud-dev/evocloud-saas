package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#BackupConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config._name)-backup-scripts"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: {
		if #config.database.type == "sqlite" {
			"sqlite-backup.sh": """
				#!/bin/sh
				set -e
				TIMESTAMP=$(date +%Y%m%d-%H%M%S)
				ARCHIVE="/backup/\(#config.backup.archivePrefix)-${TIMESTAMP}.tar.gz"
				echo "Creating SQLite backup archive..."
				tar -czf "${ARCHIVE}" -C /app/data .
				echo "Archive created: ${ARCHIVE}"

				"""
		}
		if #config.database.type != "sqlite" {
			"mysql-backup.sh": """
				#!/bin/sh
				set -e
				TIMESTAMP=$(date +%Y%m%d-%H%M%S)
				DUMP="/backup/\(#config.backup.archivePrefix)-${TIMESTAMP}.sql.gz"
				echo "Dumping MariaDB database..."
				mysqldump -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" | gzip > "${DUMP}"
				echo "Dump created: ${DUMP}"

				"""
		}
		"upload-backup.sh": """
			#!/bin/sh
			set -e
			ARCHIVE=$(ls -t /backup/*.gz 2>/dev/null | head -1)
			if [ -z "${ARCHIVE}" ]; then
			  echo "No backup archive found"; exit 1
			fi
			mc alias set s3 "${S3_ENDPOINT}" "${S3_ACCESS_KEY}" "${S3_SECRET_KEY}"

			""" + [
			if #config.backup.s3.createBucketIfNotExists {
				"""
					mc mb --ignore-existing "s3/${S3_BUCKET}"

					"""
			},
			"",
		][0] + """
			mc cp "${ARCHIVE}" "s3/${S3_BUCKET}/${S3_PREFIX}/$(basename "${ARCHIVE}")"
			echo "Upload complete: $(basename "${ARCHIVE}")"

			"""
	}
}

#BackupCronJob: batchv1.#CronJob & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(#config._name)-backup"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: batchv1.#CronJobSpec & {
		schedule:                   #config.backup.schedule
		suspend:                    #config.backup.suspend
		concurrencyPolicy:          #config.backup.concurrencyPolicy
		successfulJobsHistoryLimit: #config.backup.successfulJobsHistoryLimit
		failedJobsHistoryLimit:     #config.backup.failedJobsHistoryLimit
		jobTemplate: spec: {
			backoffLimit: #config.backup.backoffLimit
			template: {
				metadata: labels: #config.selector.labels & {
					"app.kubernetes.io/component": "backup"
				}
				spec: corev1.#PodSpec & {
					restartPolicy: "OnFailure"
					initContainers: [
						if #config.database.type == "sqlite" {
							name:  "sqlite-backup"
							image: "docker.io/library/busybox:1.37"
							command: ["/bin/sh", "/scripts/sqlite-backup.sh"]
							if #config.backup.resources != {} {
								resources: #config.backup.resources
							}
							volumeMounts: [
								{name: "data", mountPath: "/app/data", readOnly: true},
								{name: "backup-scratch", mountPath: "/backup"},
								{name: "scripts", mountPath: "/scripts"},
							]
						},
						if #config.database.type != "sqlite" {
							name:            "mysql-backup"
							image:           #config.backup.images.mysql.reference
							imagePullPolicy: #config.backup.images.mysql.pullPolicy
							command: ["/bin/sh", "/scripts/mysql-backup.sh"]
							env: [
								{name: "DB_HOST", value: #config._dbHost},
								{name: "DB_PORT", value: #config._dbPort},
								{name: "DB_NAME", value: #config._dbName},
								{name: "DB_USER", value: #config._dbUsername},
								{name: "DB_PASSWORD", valueFrom: secretKeyRef: {
									name: #config._dbSecretName
									key:  #config._dbSecretPasswordKey
								}},
							]
							if #config.backup.resources != {} {
								resources: #config.backup.resources
							}
							volumeMounts: [
								{name: "backup-scratch", mountPath: "/backup"},
								{name: "scripts", mountPath: "/scripts"},
							]
						},
					]
					containers: [
						{
							name:            "upload"
							image:           #config.backup.images.uploader.reference
							imagePullPolicy: #config.backup.images.uploader.pullPolicy
							command: ["/bin/sh", "/scripts/upload-backup.sh"]
							env: [
								{name: "S3_ENDPOINT", value: #config.backup.s3.endpoint},
								{name: "S3_BUCKET", value: #config.backup.s3.bucket},
								{name: "S3_PREFIX", value: #config.backup.s3.prefix},
								{name: "S3_ACCESS_KEY", valueFrom: secretKeyRef: {
									name: #config._backupSecretName
									key:  #config.backup.s3.existingSecretAccessKeyKey
								}},
								{name: "S3_SECRET_KEY", valueFrom: secretKeyRef: {
									name: #config._backupSecretName
									key:  #config.backup.s3.existingSecretSecretKeyKey
								}},
							]
							if #config.backup.resources != {} {
								resources: #config.backup.resources
							}
							volumeMounts: [
								{name: "backup-scratch", mountPath: "/backup", readOnly: true},
								{name: "scripts", mountPath: "/scripts"},
							]
						},
					]
					volumes: [
						if #config.database.type == "sqlite" {
							name: "data"
							persistentVolumeClaim: claimName: #config._dataClaimName
						},
						{
							name: "backup-scratch"
							emptyDir: {}
						},
						{
							name: "scripts"
							configMap: {
								name:        "\(#config._name)-backup-scripts"
								defaultMode: 0o755
							}
						},
					]
				}
			}
		}
	}
}
