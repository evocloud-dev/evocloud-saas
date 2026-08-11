package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#BackupCronJob: batchv1.#CronJob & {
	#config:    #Config
	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(#config.fullname)-backup"
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
			spec: batchv1.#JobSpec & {
				backoffLimit: #config.backup.backoffLimit
				template: corev1.#PodTemplateSpec & {
					metadata: {
						labels: #config.selector.labels
					}
					spec: corev1.#PodSpec & {
						restartPolicy: "Never"
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

						initContainers: [
							{
								name:  "postgres-backup"
								image: #config.backup.images.postgresql
								command: ["/bin/sh", "/scripts/postgres-backup.sh"]
								env: [
									{
										name:  "BACKUP_ARCHIVE_PREFIX"
										value: #config.backup.archivePrefix
									},
									{
										name:  "PG_DUMP_EXTRA_ARGS"
										value: #config.backup.database.postgresDumpArgs
									},
									{
										name:  "DB_HOST"
										value: #config.backupDbHost
									},
									{
										name:  "DB_PORT"
										value: #config.backupDbPort
									},
									{
										name:  "DB_NAME"
										value: #config.backupDbName
									},
									{
										name:  "DB_USERNAME"
										value: #config.backupDbUsername
									},
									{
										name: "DB_PASSWORD"
										valueFrom: secretKeyRef: {
											name: #config.backupDbPasswordSecretName
											key:  #config.backupDbPasswordSecretKey
										}
									},
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
									},
								]
							},
						]

						containers: [
							{
								name:  "upload"
								image: #config.backup.images.uploader
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
										name:  "S3_CREATE_BUCKET_IF_NOT_EXISTS"
										value: "\( #config.backup.s3.createBucketIfNotExists )"
									},
									{
										name: "S3_ACCESS_KEY"
										valueFrom: secretKeyRef: {
											name: #config.backupSecretName
											key:  #config.backup.s3.existingSecretAccessKeyKey
										}
									},
									{
										name: "S3_SECRET_KEY"
										valueFrom: secretKeyRef: {
											name: #config.backupSecretName
											key:  #config.backup.s3.existingSecretSecretKeyKey
										}
									},
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
									},
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
						]
					}
				}
			}
		}
	}
}
