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
		labels:    _config.standardLabels
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
				metadata: labels: _config.selectorLabels & {
					"app.kubernetes.io/component": "backup"
				}
				spec: corev1.#PodSpec & {
					restartPolicy:                "Never"
					automountServiceAccountToken: false
					restartPolicy: "Never"
					if len(_config.imagePullSecrets) > 0 {
						imagePullSecrets: _config.imagePullSecrets
					}
					initContainers: [{
						name:  "archive"
						image: _config.backup.images.archiver
						command: [
							"/bin/sh",
							"-c",
							"""
							set -e
							TIMESTAMP=$(date +%Y%m%d-%H%M%S)
							ARCHIVE="/backup/\(_config.backup.archivePrefix)-${TIMESTAMP}.tar.gz"
							echo "Creating archive ${ARCHIVE}..."
							tar czf "${ARCHIVE}" -C /config .
							echo "Archive created: $(du -h "${ARCHIVE}" | cut -f1)"
							""",
						]
						volumeMounts: [
							{
								name:      "config"
								mountPath: "/config"
								readOnly:  true
							},
							{
								name:      "backup-staging"
								mountPath: "/backup"
							},
						]
						if _config.backup.resources != _|_ && len(_config.backup.resources) > 0 {
							resources: _config.backup.resources
						}
					}]
					containers: [{
						name:  "upload"
						image: _config.backup.images.uploader
						command: [
							"/bin/sh",
							"-c",
							"""
							set -e
							mc alias set s3 "${S3_ENDPOINT}" "${S3_ACCESS_KEY}" "${S3_SECRET_KEY}" --api S3v4
							if [ "\(_config.backup.s3.createBucketIfNotExists)" = "true" ]; then
							  mc mb --ignore-existing "s3/${S3_BUCKET}"
							fi
							ARCHIVE=$(ls -t /backup/*.tar.gz | head -1)
							BASENAME=$(basename "${ARCHIVE}")
							mc cp "${ARCHIVE}" "s3/${S3_BUCKET}/\(_config.backup.s3.prefix)/${BASENAME}"
							echo "Uploaded ${BASENAME} to s3/${S3_BUCKET}/\(_config.backup.s3.prefix)/"
							""",
						]
						env: [
							{name: "S3_ENDPOINT", value: _config.backup.s3.endpoint},
							{name: "S3_BUCKET", value: _config.backup.s3.bucket},
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
						volumeMounts: [{
							name:      "backup-staging"
							mountPath: "/backup"
							readOnly:  true
						}]
						if _config.backup.resources != _|_ && len(_config.backup.resources) > 0 {
							resources: _config.backup.resources
						}
					}]
					volumes: [
						{
							name: "config"
							persistentVolumeClaim: claimName: _config.pvcName
						},
						{
							name: "backup-staging"
							emptyDir: {}
						},
					]
				}
			}
		}
	}
}
