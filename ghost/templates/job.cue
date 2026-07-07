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
		name:      "\(#config.#serviceName)-backup"
		namespace: #config.metadata.namespace
		labels:    #config.labels
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
				metadata: labels: #config.selector.labels
				spec: corev1.#PodSpec & {
					restartPolicy: "OnFailure"
					initContainers: [{
						name:    "content-backup"
						image:   #config.backup.images.backup
						command: ["/bin/sh", "/scripts/content-backup.sh"]
						if len(#config.backup.resources) > 0 {
							resources: #config.backup.resources
						}
						volumeMounts: [
							{name: "content", mountPath: "/var/lib/ghost/content", readOnly: true},
							{name: "backup-scratch", mountPath: "/backup"},
							{name: "scripts", mountPath: "/scripts"},
						]
					}]
					containers: [{
						name:    "upload"
						image:   #config.backup.images.uploader
						command: ["/bin/sh", "/scripts/upload-backup.sh"]
						env: [
							{name: "S3_ENDPOINT", value: #config.backup.s3.endpoint},
							{name: "S3_BUCKET", value: #config.backup.s3.bucket},
							{name: "S3_PREFIX", value: #config.backup.s3.prefix},
							{
								name: "S3_ACCESS_KEY"
								valueFrom: secretKeyRef: {
									name: #config.backup.#secretName
									key:  #config.backup.s3.existingSecretAccessKeyKey
								}
							},
							{
								name: "S3_SECRET_KEY"
								valueFrom: secretKeyRef: {
									name: #config.backup.#secretName
									key:  #config.backup.s3.existingSecretSecretKeyKey
								}
							},
						]
						if len(#config.backup.resources) > 0 {
							resources: #config.backup.resources
						}
						volumeMounts: [
							{name: "backup-scratch", mountPath: "/backup", readOnly: true},
							{name: "scripts", mountPath: "/scripts"},
						]
					}]
					volumes: [
						{
							name: "content"
							persistentVolumeClaim: claimName: #config.#contentClaimName
						},
						{name: "backup-scratch", emptyDir: {}},
						{
							name: "scripts"
							configMap: {
								name:        "\(#config.#serviceName)-backup-scripts"
								defaultMode: 493
							}
						},
					]
				}
			}
		}
	}
}