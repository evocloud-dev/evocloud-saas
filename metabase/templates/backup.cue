@extern(embed)
package templates

import (
	"text/template"

	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

_postgresBackupSh: string @embed(file="postgres-backup.sh", type=text)
_uploadBackupSh:   string @embed(file="upload-backup.sh", type=text)

#BackupScriptsConfigMap: timoniv1.#ImmutableConfig & {
	#config: #Config
	#Kind:   timoniv1.#ConfigMapKind
	#Meta: {
		#Version:  #config.metadata.#Version
		name:      #config.metadata.name + "-backup-scripts"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != timoniv1.#StdLabelName && k != timoniv1.#StdLabelVersion {
				"\(k)": v
			}
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	#Data: {
		"postgres-backup.sh": template.Execute(_postgresBackupSh, #config)
		"upload-backup.sh":   template.Execute(_uploadBackupSh, #config)
	}
}

#BackupCronJob: batchv1.#CronJob & {
	#config:            #Config
	#backupScriptsName: string
	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "backup"
	}
	spec: batchv1.#CronJobSpec & {
		schedule:                   #config.backup.schedule
		suspend:                    #config.backup.suspend
		concurrencyPolicy:          #config.backup.concurrencyPolicy
		successfulJobsHistoryLimit: #config.backup.successfulJobsHistoryLimit
		failedJobsHistoryLimit:     #config.backup.failedJobsHistoryLimit
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
								name:  "postgres-backup"
								image: #config.backup.images.postgresql
								command: ["/bin/sh", "/scripts/postgres-backup.sh"]
								env: [
									{name: "DB_HOST", value: #config.backupDbHost},
									{name: "DB_PORT", value: #config.backupDbPort},
									{name: "DB_NAME", value: #config.backupDbName},
									{name: "DB_USERNAME", value: #config.backupDbUsername},
									{
										name: "DB_PASSWORD"
										valueFrom: secretKeyRef: {
											name: #config.backupDbPasswordSecretName
											key:  #config.backupDbPasswordSecretKey
										}
									},
									if #config.backup.database.postgresDumpArgs != "" {
										{name: "PG_DUMP_EXTRA_ARGS", value: #config.backup.database.postgresDumpArgs}
									},
								]
								resources: #config.backup.resources
								volumeMounts: [
									{name: "scripts", mountPath: "/scripts"},
									{name: "backup-workdir", mountPath: "/backup/out"},
								]
							},
						]
						containers: [
							{
								name:  "upload"
								image: #config.backup.images.uploader
								command: ["/bin/sh", "/scripts/upload-backup.sh"]
								env: [
									{name: "S3_ENDPOINT", value: #config.backup.s3.endpoint},
									{name: "S3_BUCKET", value: #config.backup.s3.bucket},
									{name: "S3_PREFIX", value: #config.backup.s3.prefix},
									{name: "S3_CREATE_BUCKET_IF_NOT_EXISTS", value: "\(#config.backup.s3.createBucketIfNotExists)"},
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
								resources: #config.backup.resources
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
									name:        #backupScriptsName
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
				backoffLimit: #config.backup.backoffLimit
			}
		}
	}
}
