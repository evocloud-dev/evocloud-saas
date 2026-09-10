package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#BackupCronJobBuilder: batchv1.#CronJob & {
	_config: #Config

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(_config.fullname)-backup"
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	spec: batchv1.#CronJobSpec & {
		schedule:                   _config.backup.schedule
		suspend:                    _config.backup.suspend
		concurrencyPolicy:          batchv1.#ConcurrencyPolicy & _config.backup.concurrencyPolicy
		successfulJobsHistoryLimit: _config.backup.successfulJobsHistoryLimit
		failedJobsHistoryLimit:     _config.backup.failedJobsHistoryLimit
		jobTemplate: spec: {
			backoffLimit: _config.backup.backoffLimit
			template: {
				metadata: labels: _config.selector.labels
				spec: corev1.#PodSpec & {
					restartPolicy: "Never"
					if len(_config.imagePullSecrets) > 0 {
						imagePullSecrets: _config.imagePullSecrets
					}
					if len(_config.nodeSelector) > 0 {
						nodeSelector: _config.nodeSelector
					}
					if _config.affinity != _|_ {
						affinity: _config.affinity
					}
					if len(_config.tolerations) > 0 {
						tolerations: _config.tolerations
					}

					initContainers: [
						if _config.dbMode == "sqlite" {
							name:  "sqlite-backup"
							image: _config.backup.images.sqlite
							command: ["/bin/sh", "/scripts/sqlite-backup.sh"]
							env: [{
								name:  "BACKUP_ARCHIVE_PREFIX"
								value: _config.backup.archivePrefix
							}]
							if _config.backup.resources != _|_ {
								resources: _config.backup.resources
							}
							volumeMounts: [
								{name: "scripts", mountPath: "/scripts"},
								{name: "backup-workdir", mountPath: "/backup/out"},
								{name: "data", mountPath: "/data", readOnly: true},
							]
						},
						if _config.dbMode != "sqlite" && _config.dbVendor == "postgres" {
							name:  "postgres-backup"
							image: _config.backup.images.postgresql
							command: ["/bin/sh", "/scripts/postgres-backup.sh"]
							env: [
								{name: "BACKUP_ARCHIVE_PREFIX", value: _config.backup.archivePrefix},
								{name: "PG_DUMP_EXTRA_ARGS", value: _config.backup.database.postgresDumpArgs},
								{name: "DB_HOST", value: _config.backupDatabaseHost},
								{name: "DB_PORT", value: _config.backupDatabasePort},
								{name: "DB_NAME", value: _config.backupDatabaseName},
								{name: "DB_USERNAME", value: _config.backupDatabaseUsername},
								{
									name: "DB_PASSWORD"
									valueFrom: secretKeyRef: {
										name: _config.backupDatabasePasswordSecretName
										key:  _config.backupDatabasePasswordSecretKey
									}
								},
							]
							if _config.backup.resources != _|_ {
								resources: _config.backup.resources
							}
							volumeMounts: [
								{name: "scripts", mountPath: "/scripts"},
								{name: "backup-workdir", mountPath: "/backup/out"},
							]
						},
						if _config.dbMode != "sqlite" && _config.dbVendor == "mysql" {
							name:  "mysql-backup"
							image: _config.backup.images.mysql
							command: ["/bin/sh", "/scripts/mysql-backup.sh"]
							env: [
								{name: "BACKUP_ARCHIVE_PREFIX", value: _config.backup.archivePrefix},
								{name: "MYSQL_DUMP_EXTRA_ARGS", value: _config.backup.database.mysqlDumpArgs},
								{name: "DB_HOST", value: _config.backupDatabaseHost},
								{name: "DB_PORT", value: _config.backupDatabasePort},
								{name: "DB_NAME", value: _config.backupDatabaseName},
								{name: "DB_USERNAME", value: _config.backupDatabaseUsername},
								{
									name: "DB_PASSWORD"
									valueFrom: secretKeyRef: {
										name: _config.backupDatabasePasswordSecretName
										key:  _config.backupDatabasePasswordSecretKey
									}
								},
							]
							if _config.backup.resources != _|_ {
								resources: _config.backup.resources
							}
							volumeMounts: [
								{name: "scripts", mountPath: "/scripts"},
								{name: "backup-workdir", mountPath: "/backup/out"},
							]
						},
					]

					containers: [{
						name:  "upload"
						image: _config.backup.images.uploader
						command: ["/bin/sh", "/scripts/upload-backup.sh"]
						env: [
							{name: "S3_ENDPOINT", value: _config.backup.s3.endpoint},
							{name: "S3_BUCKET", value: _config.backup.s3.bucket},
							{name: "S3_PREFIX", value: _config.backup.s3.prefix},
							{name: "S3_CREATE_BUCKET_IF_NOT_EXISTS", value: "\(_config.backup.s3.createBucketIfNotExists)"},
							{
								name: "S3_ACCESS_KEY"
								valueFrom: secretKeyRef: {
									name: _config.backupSecretName
									key:  _config.backup.s3.existingSecretAccessKeyKey
								}
							},
							{
								name: "S3_SECRET_KEY"
								valueFrom: secretKeyRef: {
									name: _config.backupSecretName
									key:  _config.backup.s3.existingSecretSecretKeyKey
								}
							},
						]
						if _config.backup.resources != _|_ {
							resources: _config.backup.resources
						}
						volumeMounts: [
							{name: "scripts", mountPath: "/scripts"},
							{name: "backup-workdir", mountPath: "/backup/out"},
						]
					}]

					volumes: [
						{
							name: "scripts"
							configMap: {
								name:        "\(_config.fullname)-backup-scripts"
								defaultMode: 0o755
							}
						},
						{
							name: "backup-workdir"
							emptyDir: {}
						},
						if _config.dbMode == "sqlite" {
							name: "data"
							persistentVolumeClaim: claimName: [
								if _config.persistence.existingClaim != "" {_config.persistence.existingClaim},
								"\(_config.fullname)-data",
							][0]
						},
					]
				}
			}
		}
	}
}
