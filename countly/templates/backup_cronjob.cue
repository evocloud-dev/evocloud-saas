@experiment(try)
package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#BackupCronJob: batchv1.#CronJob & {
	#config: #Config
	apiVersion: "batch/v1"
	kind: "CronJob"
	metadata: timoniv1.#MetaComponent & {
		#Meta: #config.metadata
		#Component: "backup"
	}
	spec: batchv1.#CronJobSpec & {
		schedule: #config.backup.schedule
		suspend: #config.backup.suspend
		concurrencyPolicy: #config.backup.concurrencyPolicy
		successfulJobsHistoryLimit: #config.backup.successfulJobsHistoryLimit
		failedJobsHistoryLimit: #config.backup.failedJobsHistoryLimit
		jobTemplate: {
			spec: batchv1.#JobSpec & {
				template: corev1.#PodTemplateSpec & {
					metadata: {
						labels: #config.selector.labels
					}
					spec: corev1.#PodSpec & {
						restartPolicy: "Never"
						initContainers: [
							{
								name: "mongodb-backup"
								image: #config.backup.images.mongodb
								command: ["/bin/sh", "/scripts/mongodb-backup.sh"]
								env: [
									{name: "BACKUP_ARCHIVE_PREFIX", value: #config.backup.archivePrefix},
									{name: "MONGODUMP_EXTRA_ARGS", value: #config.backup.database.mongodumpArgs},
									if !(#config.externalMongodb.enabled) {
										{name: "MONGODB_ROOT_PASSWORD", valueFrom: corev1.#EnvVarSource & {secretKeyRef: corev1.#SecretKeySelector & {name: #config.mongodbSecretName, key: "mongodb-root-password"}}}
									}
									{name: "MONGODB_URI", value: #config.backupMongodbURI}
								]
								resources: #config.backup.resources
								volumeMounts: [
									{name: "scripts", mountPath: "/scripts"},
									{name: "backup-workdir", mountPath: "/backup/out"}
								]
							}
						]
						containers: [
							{
								name: "upload"
								image: #config.backup.images.uploader
								command: ["/bin/sh", "/scripts/upload-backup.sh"]
								env: [
									{name: "S3_ENDPOINT", value: #config.backup.s3.endpoint},
									{name: "S3_BUCKET", value: #config.backup.s3.bucket},
									{name: "S3_PREFIX", value: #config.backup.s3.prefix},
									{
										name: "S3_CREATE_BUCKET_IF_NOT_EXISTS"
										if #config.backup.s3.createBucketIfNotExists {
											value: "true"
										} else {
											value: "false"
										}
									},
									{name: "S3_ACCESS_KEY", valueFrom: corev1.#EnvVarSource & {secretKeyRef: corev1.#SecretKeySelector & {name: #config.backupSecretName, key: #config.backup.s3.existingSecretAccessKeyKey}}},
									{name: "S3_SECRET_KEY", valueFrom: corev1.#EnvVarSource & {secretKeyRef: corev1.#SecretKeySelector & {name: #config.backupSecretName, key: #config.backup.s3.existingSecretSecretKeyKey}}}
								]
								resources: #config.backup.resources
								volumeMounts: [
									{name: "scripts", mountPath: "/scripts"},
									{name: "backup-workdir", mountPath: "/backup/out"},
								]
							}
						]
						volumes: [
							{name: "scripts", configMap: {name: #config.metadata.name + "-backup-scripts", defaultMode: 0o755}},
							{name: "backup-workdir", emptyDir: {}}
						]
					}
				}
				backoffLimit: #config.backup.backoffLimit
			}
		}
	}
}