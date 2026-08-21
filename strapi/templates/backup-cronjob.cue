package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#BackupCronJob: batchv1.#CronJob & {
	#config: #Config
	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(#config.fullname)-backup"
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
				metadata: labels: #config.metadata.labels
				spec: corev1.#PodSpec & {
					restartPolicy: "Never"
					if len(#config.imagePullSecrets) > 0 {
						imagePullSecrets: #config.imagePullSecrets
					}
					if len(#config.nodeSelector) > 0 {
						nodeSelector: #config.nodeSelector
					}
					if len(#config.affinity) > 0 {
						affinity: #config.affinity
					}
					if len(#config.tolerations) > 0 {
						tolerations: #config.tolerations
					}

					initContainers: [
						if #config.persistence.enabled && #config.resolvedDbMode != "sqlite" {
							name:            "uploads-backup"
							image:           #config.backup.images.utility
							imagePullPolicy: "IfNotPresent"
							command: ["/bin/sh", "/scripts/uploads-backup.sh"]
							env: [
								{name: "BACKUP_ARCHIVE_PREFIX", value: #config.backup.archivePrefix},
							]
							if len(#config.backup.resources) > 0 {
								resources: #config.backup.resources
							}
							volumeMounts: [
								{name: "scripts", mountPath: "/scripts"},
								{name: "backup-workdir", mountPath: "/backup/out"},
								{name: "uploads-data", mountPath: "/data", readOnly: true},
							]
						},
						if #config.resolvedDbMode == "sqlite" {
							name:            "sqlite-backup"
							image:           #config.backup.images.utility
							imagePullPolicy: "IfNotPresent"
							command: ["/bin/sh", "/scripts/sqlite-backup.sh"]
							env: [
								{name: "BACKUP_ARCHIVE_PREFIX", value: #config.backup.archivePrefix},
							]
							if len(#config.backup.resources) > 0 {
								resources: #config.backup.resources
							}
							volumeMounts: [
								{name: "scripts", mountPath: "/scripts"},
								{name: "backup-workdir", mountPath: "/backup/out"},
								{name: "data", mountPath: "/data", readOnly: true},
							]
						},
						if #config.resolvedDbMode == "postgresql" || (#config.resolvedDbMode == "external" && #config.database.external.vendor == "postgres") {
							name:            "postgres-backup"
							image:           #config.backup.images.postgresql
							imagePullPolicy: "IfNotPresent"
							command: ["/bin/sh", "/scripts/postgres-backup.sh"]
							env: [
								{name: "BACKUP_ARCHIVE_PREFIX", value: #config.backup.archivePrefix},
								{name: "PG_DUMP_EXTRA_ARGS", value: #config.backup.database.postgresDumpArgs},
								{
									name: "DB_HOST"
									value: [
										if #config.backup.database.host != "" {#config.backup.database.host},
										if #config.resolvedDbMode == "postgresql" {"\(#config.fullname)-postgresql"},
										if #config.resolvedDbMode == "external" {#config.database.external.host},
									][0]
								},
								{
									name: "DB_PORT"
									value: [
										if #config.backup.database.port != "" {#config.backup.database.port},
										if #config.resolvedDbMode == "postgresql" {"5432"},
										if #config.resolvedDbMode == "external" {
											if #config.database.external.port != "" {#config.database.external.port}
											if #config.database.external.port == "" {"5432"}
										},
									][0]
								},
								{
									name: "DB_NAME"
									value: [
										if #config.backup.database.name != "" {#config.backup.database.name},
										if #config.resolvedDbMode == "postgresql" {#config.postgresql.auth.database},
										if #config.resolvedDbMode == "external" {#config.database.external.name},
									][0]
								},
								{
									name: "DB_USERNAME"
									value: [
										if #config.backup.database.username != "" {#config.backup.database.username},
										if #config.resolvedDbMode == "postgresql" {#config.postgresql.auth.username},
										if #config.resolvedDbMode == "external" {#config.database.external.username},
									][0]
								},
								{
									name: "DB_PASSWORD"
									valueFrom: secretKeyRef: {
										name: [
											if #config.backup.database.existingSecret != "" {#config.backup.database.existingSecret},
											if #config.resolvedDbMode == "postgresql" {"\(#config.fullname)-postgresql-auth"},
											if #config.resolvedDbMode == "external" {
												if #config.database.external.existingSecret != "" {#config.database.external.existingSecret}
												if #config.database.external.existingSecret == "" {"\(#config.fullname)-database"}
											},
										][0]
										key: [
											if #config.backup.database.existingSecret != "" {#config.backup.database.existingSecretPasswordKey},
											if #config.resolvedDbMode == "postgresql" {"database-password"},
											if #config.resolvedDbMode == "external" {
												if #config.database.external.existingSecret != "" {#config.database.external.existingSecretPasswordKey}
												if #config.database.external.existingSecret == "" {"database-password"}
											},
										][0]
									}
								},
							]
							if len(#config.backup.resources) > 0 {
								resources: #config.backup.resources
							}
							volumeMounts: [
								{name: "scripts", mountPath: "/scripts"},
								{name: "backup-workdir", mountPath: "/backup/out"},
							]
						},
						if #config.resolvedDbMode == "mysql" || (#config.resolvedDbMode == "external" && #config.database.external.vendor == "mysql") {
							name:            "mysql-backup"
							image:           #config.backup.images.mysql
							imagePullPolicy: "IfNotPresent"
							command: ["/bin/sh", "/scripts/mysql-backup.sh"]
							env: [
								{name: "BACKUP_ARCHIVE_PREFIX", value: #config.backup.archivePrefix},
								{name: "MYSQL_DUMP_EXTRA_ARGS", value: #config.backup.database.mysqlDumpArgs},
								{
									name: "DB_HOST"
									value: [
										if #config.backup.database.host != "" {#config.backup.database.host},
										if #config.resolvedDbMode == "mysql" {"\(#config.fullname)-mysql"},
										if #config.resolvedDbMode == "external" {#config.database.external.host},
									][0]
								},
								{
									name: "DB_PORT"
									value: [
										if #config.backup.database.port != "" {#config.backup.database.port},
										if #config.resolvedDbMode == "mysql" {"3306"},
										if #config.resolvedDbMode == "external" {
											if #config.database.external.port != "" {#config.database.external.port}
											if #config.database.external.port == "" {"3306"}
										},
									][0]
								},
								{
									name: "DB_NAME"
									value: [
										if #config.backup.database.name != "" {#config.backup.database.name},
										if #config.resolvedDbMode == "mysql" {#config.mysql.auth.database},
										if #config.resolvedDbMode == "external" {#config.database.external.name},
									][0]
								},
								{
									name: "DB_USERNAME"
									value: [
										if #config.backup.database.username != "" {#config.backup.database.username},
										if #config.resolvedDbMode == "mysql" {#config.mysql.auth.username},
										if #config.resolvedDbMode == "external" {#config.database.external.username},
									][0]
								},
								{
									name: "DB_PASSWORD"
									valueFrom: secretKeyRef: {
										name: [
											if #config.backup.database.existingSecret != "" {#config.backup.database.existingSecret},
											if #config.resolvedDbMode == "mysql" {"\(#config.fullname)-mysql-auth"},
											if #config.resolvedDbMode == "external" {
												if #config.database.external.existingSecret != "" {#config.database.external.existingSecret}
												if #config.database.external.existingSecret == "" {"\(#config.fullname)-database"}
											},
										][0]
										key: [
											if #config.backup.database.existingSecret != "" {#config.backup.database.existingSecretPasswordKey},
											if #config.resolvedDbMode == "mysql" {"database-password"},
											if #config.resolvedDbMode == "external" {
												if #config.database.external.existingSecret != "" {#config.database.external.existingSecretPasswordKey}
												if #config.database.external.existingSecret == "" {"database-password"}
											},
										][0]
									}
								},
							]
							if len(#config.backup.resources) > 0 {
								resources: #config.backup.resources
							}
							volumeMounts: [
								{name: "scripts", mountPath: "/scripts"},
								{name: "backup-workdir", mountPath: "/backup/out"},
							]
						},
					]

					containers: [
						{
							name:            "upload"
							image:           #config.backup.images.uploader
							imagePullPolicy: "IfNotPresent"
							command: ["/bin/sh", "/scripts/upload-backup.sh"]
							env: [
								{name: "S3_ENDPOINT", value: #config.backup.s3.endpoint},
								{name: "S3_BUCKET", value: #config.backup.s3.bucket},
								{name: "S3_PREFIX", value: #config.backup.s3.prefix},
								{name: "S3_CREATE_BUCKET_IF_NOT_EXISTS", value: [if #config.backup.s3.createBucketIfNotExists {"true"}, "false"][0]},
								{
									name: "S3_ACCESS_KEY"
									valueFrom: secretKeyRef: {
										name: [
											if #config.backup.s3.existingSecret != "" {#config.backup.s3.existingSecret},
											"\(#config.fullname)-backup-s3",
										][0]
										key: #config.backup.s3.existingSecretAccessKeyKey
									}
								},
								{
									name: "S3_SECRET_KEY"
									valueFrom: secretKeyRef: {
										name: [
											if #config.backup.s3.existingSecret != "" {#config.backup.s3.existingSecret},
											"\(#config.fullname)-backup-s3",
										][0]
										key: #config.backup.s3.existingSecretSecretKeyKey
									}
								},
							]
							if len(#config.backup.resources) > 0 {
								resources: #config.backup.resources
							}
							volumeMounts: [
								{name: "scripts", mountPath: "/scripts"},
								{name: "backup-workdir", mountPath: "/backup/out"},
							]
						},
					]
					volumes: [
						{
							name: "scripts"
							configMap: {
								name:        "\(#config.fullname)-backup-scripts"
								defaultMode: 0o755
							}
						},
						{
							name: "backup-workdir"
							emptyDir: {}
						},
						if #config.resolvedDbMode == "sqlite" {
							name: "data"
							persistentVolumeClaim: claimName: [
								if #config.persistence.existingClaim != "" {#config.persistence.existingClaim},
								if #config.persistence.existingClaim == "" {"\(#config.fullname)-data"},
							][0]
						},
						if #config.persistence.enabled && #config.resolvedDbMode != "sqlite" {
							name: "uploads-data"
							persistentVolumeClaim: claimName: [
								if #config.persistence.existingClaim != "" {#config.persistence.existingClaim},
								if #config.persistence.existingClaim == "" {"\(#config.fullname)-data"},
							][0]
						},
					]
				}
			}
		}
	}
}
