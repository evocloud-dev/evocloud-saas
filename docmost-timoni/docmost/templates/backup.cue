package templates

import (
	corev1 "k8s.io/api/core/v1"
	batchv1 "k8s.io/api/batch/v1"
)

#BackupConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-backup-scripts"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: {
		"postgres-backup.sh": """
			#!/bin/sh
			set -eu
			timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
			archive="/backup/out/${BACKUP_ARCHIVE_PREFIX}-postgresql-${timestamp}.sql.gz"
			mkdir -p /backup/out
			export PGPASSWORD="${DB_PASSWORD}"
			pg_dump ${PG_DUMP_EXTRA_ARGS:-} \\
			  --host="${DB_HOST}" \\
			  --port="${DB_PORT}" \\
			  --username="${DB_USERNAME}" \\
			  --dbname="${DB_NAME}" | gzip -c > "${archive}"
			printf "%s" "${archive}" > /backup/out/backup-file
			"""
		"upload-backup.sh": """
			#!/bin/sh
			set -eu
			archive="$(cat /backup/out/backup-file)"
			target="backup/${S3_BUCKET}"
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

#BackupCronJob: batchv1.#CronJob & {
	#config:         #Config
	#backupCmName:   string
	apiVersion:     "batch/v1"
	kind:           "CronJob"
	metadata: {
		name:      "\(#config.metadata.name)-backup"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: batchv1.#CronJobSpec & {
		schedule:          #config.backup.schedule
		suspend:           #config.backup.suspend
		concurrencyPolicy: #config.backup.concurrencyPolicy
		if #config.backup.successfulJobsHistoryLimit != _|_ {
			successfulJobsHistoryLimit: #config.backup.successfulJobsHistoryLimit
		}
		if #config.backup.failedJobsHistoryLimit != _|_ {
			failedJobsHistoryLimit: #config.backup.failedJobsHistoryLimit
		}
		jobTemplate: batchv1.#JobTemplateSpec & {
			spec: {
				if #config.backup.backoffLimit != _|_ {
					backoffLimit: #config.backup.backoffLimit
				}
				template: {
					metadata: labels: #config.selector.labels
					spec: corev1.#PodSpec & {
						restartPolicy: "Never"
						serviceAccountName: {
							if #config.serviceAccount.name != "" { #config.serviceAccount.name }
							if #config.serviceAccount.name == "" { #config.metadata.name }
						}
						terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
						if #config.imagePullSecrets != _|_ {
							imagePullSecrets: #config.imagePullSecrets
						}
						if #config.nodeSelector != _|_ {
							nodeSelector: #config.nodeSelector
						}
						if #config.affinity != _|_ {
							affinity: #config.affinity
						}
						if #config.tolerations != _|_ {
							tolerations: #config.tolerations
						}

						let _dbMode = {
							if #config.database.mode == "external" { "external" }
							if #config.database.mode == "postgresql" { "postgresql" }
							if #config.database.mode == "auto" {
								if #config.database.external.host != "" || #config.database.external.existingSecret != "" { "external" }
								if #config.database.external.host == "" && #config.database.external.existingSecret == "" { "postgresql" }
							}
						}
						let _dbHost = {
							if _dbMode == "external" { #config.database.external.host }
							if _dbMode == "postgresql" { "\(#config.metadata.name)-postgresql" }
						}
						let _dbPort = {
							if _dbMode == "external" { "\(#config.database.external.port)" }
							if _dbMode == "postgresql" { "5432" }
						}
						let _dbName = {
							if _dbMode == "external" { #config.database.external.name }
							if _dbMode == "postgresql" { #config.postgresql.auth.database }
						}
						let _dbUsername = {
							if _dbMode == "external" { #config.database.external.username }
							if _dbMode == "postgresql" { #config.postgresql.auth.username }
						}
						let _dbSecretName = {
							if _dbMode == "external" && #config.database.external.existingSecret != "" { #config.database.external.existingSecret }
							if _dbMode == "external" && #config.database.external.existingSecret == "" { "\(#config.metadata.name)-app" }
							if _dbMode == "postgresql" { "\(#config.metadata.name)-app" }
						}
						let _dbSecretKey = {
							if _dbMode == "external" && #config.database.external.existingSecret != "" { #config.database.external.existingSecretPasswordKey }
							if _dbMode == "external" && #config.database.external.existingSecret == "" { "database-password" }
							if _dbMode == "postgresql" { "database-password" }
						}

						let _s3SecretName = {
							if #config.backup.s3.existingSecret != "" { #config.backup.s3.existingSecret }
							if #config.backup.s3.existingSecret == "" { "\(#config.metadata.name)-app" }
						}

						initContainers: [{
							name:            "postgres-backup"
							image:           #config.backup.images.postgresql
							imagePullPolicy: "IfNotPresent"
							command: ["/bin/sh", "/scripts/postgres-backup.sh"]
							env: [
								{
									name:  "BACKUP_ARCHIVE_PREFIX"
									value: #config.backup.archivePrefix
								},
								{
									name:  "DB_HOST"
									value: _dbHost
								},
								{
									name:  "DB_PORT"
									value: _dbPort
								},
								{
									name:  "DB_NAME"
									value: _dbName
								},
								{
									name:  "DB_USERNAME"
									value: _dbUsername
								},
								{
									name: "DB_PASSWORD"
									valueFrom: secretKeyRef: {
										name: _dbSecretName
										key:  _dbSecretKey
									}
								},
								{
									name:  "PG_DUMP_EXTRA_ARGS"
									value: #config.backup.database.pgDumpArgs
								}
							]
							if #config.backup.resources != _|_ {
								resources: #config.backup.resources
							}
							volumeMounts: [
								{
									name:      "scripts"
									mountPath: "/scripts"
								},
								{
									name:      "backup-workdir"
									mountPath: "/backup/out"
								}
							]
						}]

						containers: [{
							name:            "upload"
							image:           #config.backup.images.uploader
							imagePullPolicy: "IfNotPresent"
							command: ["/bin/sh", "/scripts/upload-backup.sh"]
							env: [
								{
									name:  "S3_ENDPOINT"
									value: #config.backup.s3.endpoint
								},
								{
									name:  "S3_BUCKET"
									value: #config.backup.s3.bucket
								},
								{
									name:  "S3_PREFIX"
									value: #config.backup.s3.prefix
								},
								{
									name: "S3_CREATE_BUCKET_IF_NOT_EXISTS"
									value: {
										if #config.backup.s3.createBucketIfNotExists { "true" }
										if !#config.backup.s3.createBucketIfNotExists { "false" }
									}
								},
								{
									name: "S3_ACCESS_KEY"
									valueFrom: secretKeyRef: {
										name: _s3SecretName
										key:  #config.backup.s3.existingSecretAccessKeyKey
									}
								},
								{
									name: "S3_SECRET_KEY"
									valueFrom: secretKeyRef: {
										name: _s3SecretName
										key:  #config.backup.s3.existingSecretSecretKeyKey
									}
								}
							]
							if #config.backup.resources != _|_ {
								resources: #config.backup.resources
							}
							volumeMounts: [
								{
									name:      "scripts"
									mountPath: "/scripts"
								},
								{
									name:      "backup-workdir"
									mountPath: "/backup/out"
								}
							]
						}]

						volumes: [
							{
								name: "scripts"
								configMap: {
									name:        #backupCmName
									defaultMode: 493 // 0755 octal
								}
							},
							{
								name: "backup-workdir"
								emptyDir: {}
							}
						]
					}
				}
			}
		}
	}
}
