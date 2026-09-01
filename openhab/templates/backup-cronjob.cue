package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#BackupCronJobBuilder: {
	_config: #Config

	_s3SecretName: [
		if _config.backup.s3.existingSecret != "" {_config.backup.s3.existingSecret},
		"\(_config.fullname)-backup",
	][0]

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(_config.fullname)-backup"
		namespace: _config.namespace
		labels:    _config.metadata.labels
	}
	spec: batchv1.#CronJobSpec & {
		schedule:                   _config.backup.schedule
		suspend:                    _config.backup.suspend
		concurrencyPolicy:          _config.backup.concurrencyPolicy
		successfulJobsHistoryLimit: _config.backup.successfulJobsHistoryLimit
		failedJobsHistoryLimit:     _config.backup.failedJobsHistoryLimit
		jobTemplate: spec: {
			backoffLimit: _config.backup.backoffLimit
			template: spec: corev1.#PodSpec & {
				restartPolicy: "OnFailure"
				securityContext: {
					runAsUser:  9001
					runAsGroup: 9001
					fsGroup:    9001
				}
				initContainers: [{
					name:            "backup"
					image:           "\(_config.backup.images.utility.repository):\(_config.backup.images.utility.tag)"
					imagePullPolicy: _config.backup.images.utility.pullPolicy
					command: ["/bin/sh", "/scripts/backup.sh"]
					if _config.backup.resources != _|_ {
						resources: _config.backup.resources
					}
					volumeMounts: [
						if _config.backup.include.userdata {
							name:      "userdata"
							mountPath: "/openhab/userdata"
							readOnly:  true
						},
						if _config.backup.include.conf {
							name:      "conf"
							mountPath: "/openhab/conf"
							readOnly:  true
						},
						{
							name:      "backup-scripts"
							mountPath: "/scripts"
							readOnly:  true
						},
						{
							name:      "backup-temp"
							mountPath: "/tmp"
						},
					]
				}]
				containers: [{
					name:            "upload"
					image:           "\(_config.backup.images.uploader.repository):\(_config.backup.images.uploader.tag)"
					imagePullPolicy: _config.backup.images.uploader.pullPolicy
					command: ["/bin/sh", "/scripts/upload.sh"]
					env: [
						{name: "S3_ENDPOINT", value: _config.backup.s3.endpoint},
						{name: "S3_BUCKET", value: _config.backup.s3.bucket},
						{name: "S3_PREFIX", value: _config.backup.s3.prefix},
						{
							name: "S3_ACCESS_KEY"
							valueFrom: secretKeyRef: {
								name: _s3SecretName
								key:  "access-key"
							}
						},
						{
							name: "S3_SECRET_KEY"
							valueFrom: secretKeyRef: {
								name: _s3SecretName
								key:  "secret-key"
							}
						},
					]
					if _config.backup.resources != _|_ {
						resources: _config.backup.resources
					}
					volumeMounts: [
						{
							name:      "backup-scripts"
							mountPath: "/scripts"
							readOnly:  true
						},
						{
							name:      "backup-temp"
							mountPath: "/tmp"
						},
					]
				}]
				volumes: [
					if _config.backup.include.userdata {
						name: "userdata"
						persistentVolumeClaim: claimName: _config.userdataPvcName
					},
					if _config.backup.include.conf {
						name: "conf"
						persistentVolumeClaim: claimName: _config.confPvcName
					},
					{
						name: "backup-scripts"
						configMap: {
							name:        "\(_config.fullname)-backup-scripts"
							defaultMode: 493 // 0755
						}
					},
					{
						name: "backup-temp"
						emptyDir: {}
					},
				]
			}
		}
	}
}
