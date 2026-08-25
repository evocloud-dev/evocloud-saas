package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#BackupCronJob: {
	#config: #Config

	backupSecretName: [
		if #config.backup.s3.existingSecret != "" {
			#config.backup.s3.existingSecret
		},
		"\(#config.fullname)-backup",
	][0]

	backupDbHost: [
		if #config.backup.database.host != "" {
			#config.backup.database.host
		},
		#config.databaseHost,
	][0]

	backupDbPort: [
		if #config.backup.database.port != "" {
			#config.backup.database.port
		},
		#config.databasePort,
	][0]

	backupDbName: [
		if #config.backup.database.name != "" {
			#config.backup.database.name
		},
		#config.databaseName,
	][0]

	backupDbUsername: [
		if #config.backup.database.username != "" {
			#config.backup.database.username
		},
		#config.databaseUsername,
	][0]

	backupDbPasswordSecretName: [
		if #config.backup.database.existingSecret != "" {
			#config.backup.database.existingSecret
		},
		#config.databaseSecretName,
	][0]

	backupDbPasswordSecretKey: [
		if #config.backup.database.existingSecret != "" {
			#config.backup.database.existingSecretPasswordKey
		},
		"database-password",
	][0]

	pvcClaimName: [
		if #config.persistence.existingClaim != "" {
			#config.persistence.existingClaim
		},
		"\(#config.fullname)-data",
	][0]

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
			template: spec: corev1.#PodSpec & {
				restartPolicy: "Never"
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				initContainers: [
					if #config.databaseMode == "sqlite" {
						name:    "sqlite-backup"
						image:   #config.backup.images.sqlite
						command: ["/bin/sh", "/scripts/sqlite-backup.sh"]
						env: [{
							name:  "BACKUP_ARCHIVE_PREFIX"
							value: #config.backup.archivePrefix
						}]
						if #config.backup.resources != _|_ {
							resources: #config.backup.resources
						}
						volumeMounts: [{
							name:      "scripts"
							mountPath: "/scripts"
						}, {
							name:      "backup-workdir"
							mountPath: "/backup/out"
						}, {
							name:      "data"
							mountPath: "/data"
							readOnly:  true
						}]
					},
					if #config.databaseVendor == "postgres" {
						name:    "postgres-backup"
						image:   #config.backup.images.postgresql
						command: ["/bin/sh", "/scripts/postgres-backup.sh"]
						env: [{
							name:  "BACKUP_ARCHIVE_PREFIX"
							value: #config.backup.archivePrefix
						}, {
							name:  "PG_DUMP_EXTRA_ARGS"
							value: #config.backup.database.postgresDumpArgs
						}, {
							name:  "DB_HOST"
							value: backupDbHost
						}, {
							name:  "DB_PORT"
							value: backupDbPort
						}, {
							name:  "DB_NAME"
							value: backupDbName
						}, {
							name:  "DB_USERNAME"
							value: backupDbUsername
						}, {
							name: "DB_PASSWORD"
							valueFrom: secretKeyRef: {
								name: backupDbPasswordSecretName
								key:  backupDbPasswordSecretKey
							}
						}]
						if #config.backup.resources != _|_ {
							resources: #config.backup.resources
						}
						volumeMounts: [{
							name:      "scripts"
							mountPath: "/scripts"
						}, {
							name:      "backup-workdir"
							mountPath: "/backup/out"
						}]
					},
					if #config.databaseVendor == "mysql" {
						name:    "mysql-backup"
						image:   #config.backup.images.mysql
						command: ["/bin/sh", "/scripts/mysql-backup.sh"]
						env: [{
							name:  "BACKUP_ARCHIVE_PREFIX"
							value: #config.backup.archivePrefix
						}, {
							name:  "MYSQL_DUMP_EXTRA_ARGS"
							value: #config.backup.database.mysqlDumpArgs
						}, {
							name:  "DB_HOST"
							value: backupDbHost
						}, {
							name:  "DB_PORT"
							value: backupDbPort
						}, {
							name:  "DB_NAME"
							value: backupDbName
						}, {
							name:  "DB_USERNAME"
							value: backupDbUsername
						}, {
							name: "DB_PASSWORD"
							valueFrom: secretKeyRef: {
								name: backupDbPasswordSecretName
								key:  backupDbPasswordSecretKey
							}
						}]
						if #config.backup.resources != _|_ {
							resources: #config.backup.resources
						}
						volumeMounts: [{
							name:      "scripts"
							mountPath: "/scripts"
						}, {
							name:      "backup-workdir"
							mountPath: "/backup/out"
						}]
					},
				]
				containers: [{
					name:    "upload"
					image:   #config.backup.images.uploader
					command: ["/bin/sh", "/scripts/upload-backup.sh"]
					env: [{
						name:  "S3_ENDPOINT"
						value: #config.backup.s3.endpoint
					}, {
						name:  "S3_BUCKET"
						value: #config.backup.s3.bucket
					}, {
						name:  "S3_PREFIX"
						value: #config.backup.s3.prefix
					}, {
						name:  "S3_CREATE_BUCKET_IF_NOT_EXISTS"
						value: "\( #config.backup.s3.createBucketIfNotExists )"
					}, {
						name: "S3_ACCESS_KEY"
						valueFrom: secretKeyRef: {
							name: backupSecretName
							key:  #config.backup.s3.existingSecretAccessKeyKey
						}
					}, {
						name: "S3_SECRET_KEY"
						valueFrom: secretKeyRef: {
							name: backupSecretName
							key:  #config.backup.s3.existingSecretSecretKeyKey
						}
					}]
					if #config.backup.resources != _|_ {
						resources: #config.backup.resources
					}
					volumeMounts: [{
						name:      "scripts"
						mountPath: "/scripts"
					}, {
						name:      "backup-workdir"
						mountPath: "/backup/out"
					}]
				}]
				volumes: [
					{
						name: "scripts"
						configMap: {
							name:        "\(#config.fullname)-backup-scripts"
							defaultMode: 493
						}
					},
					{
						name: "backup-workdir"
						emptyDir: {}
					},
					if #config.databaseMode == "sqlite" {
						name: "data"
						persistentVolumeClaim: claimName: pvcClaimName
					},
				]
			}
		}
	}
}
