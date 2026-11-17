package templates

import (
	batchv1 "k8s.io/api/batch/v1"
)

// #BackupCronJob mirrors templates/backup-cronjob.yaml.
#BackupCronJob: batchv1.#CronJob & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(#config.metadata.name)-backup"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "backup"
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
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
				metadata: labels: #config.selector.labels & {
					"app.kubernetes.io/component": "backup"
				}
				spec: {
					restartPolicy: "Never"
					if #config.backup.s3.credentialsFromPodIdentity {
						serviceAccountName:           #config._backupSaName
						automountServiceAccountToken: #config.backup.serviceAccount.automountServiceAccountToken
					}
					if !#config.backup.s3.credentialsFromPodIdentity {
						serviceAccountName:           #config._saName
						automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
					}
					securityContext: #config.podSecurityContext
					if len(#config.imagePullSecrets) > 0 {
						imagePullSecrets: #config.imagePullSecrets
					}
					initContainers: [{
						name:  "archive"
						image: #config.backup.images.archiver
						command: [
							"/bin/sh",
							"-c",
							"""
							set -e
							TIMESTAMP=$(date +%Y%m%d-%H%M%S)
							ARCHIVE="/backup/\(#config.backup.archivePrefix)-${TIMESTAMP}.tar.gz"
							echo "Creating archive ${ARCHIVE}..."
							tar czf "${ARCHIVE}" -C /var/cache/ntfy .
							echo "Archive created: $(du -h "${ARCHIVE}" | cut -f1)"
							""",
						]
						volumeMounts: [
							{name: "data", mountPath: "/var/cache/ntfy", readOnly: true},
							{name: "backup-staging", mountPath: "/backup"},
							{name: "backup-tmp", mountPath: "/tmp"},
						]
						if len(#config.backup.resources) > 0 {
							resources: #config.backup.resources
						}
						securityContext: #config.securityContext
					}]
					containers: [{
						name:  "upload"
						image: #config.backup.images.uploader
						command: [
							"/bin/sh",
							"-c",
							if #config.backup.s3.credentialsFromPodIdentity {
								"""
								set -e
								export MC_HOST_s3="${S3_ENDPOINT}"
								STS_DOMAIN="amazonaws.com"
								case "${AWS_REGION}" in
								  cn-*) STS_DOMAIN="amazonaws.com.cn" ;;
								esac
								export MC_STS_ENDPOINT_s3="https://sts.${AWS_REGION}.${STS_DOMAIN}"
								\([if #config.backup.s3.createBucketIfNotExists {"mc mb --ignore-existing --region=\"${AWS_REGION}\" \"s3/${S3_BUCKET}\""}, ""][0])
								ARCHIVE=$(ls -t /backup/*.tar.gz | head -1)
								BASENAME=$(basename "${ARCHIVE}")
								mc cp "${ARCHIVE}" "s3/${S3_BUCKET}/\(#config.backup.s3.prefix)/${BASENAME}"
								echo "Uploaded ${BASENAME} to s3/${S3_BUCKET}/\(#config.backup.s3.prefix)/"
								"""
							},
							if !#config.backup.s3.credentialsFromPodIdentity {
								"""
								set -e
								mc alias set s3 "${S3_ENDPOINT}" "${S3_ACCESS_KEY}" "${S3_SECRET_KEY}" --api S3v4
								\([if #config.backup.s3.createBucketIfNotExists {"mc mb --ignore-existing \"s3/${S3_BUCKET}\""}, ""][0])
								ARCHIVE=$(ls -t /backup/*.tar.gz | head -1)
								BASENAME=$(basename "${ARCHIVE}")
								mc cp "${ARCHIVE}" "s3/${S3_BUCKET}/\(#config.backup.s3.prefix)/${BASENAME}"
								echo "Uploaded ${BASENAME} to s3/${S3_BUCKET}/\(#config.backup.s3.prefix)/"
								"""
							},
						]
						env: [
							{name: "S3_ENDPOINT", value: #config.backup.s3.endpoint},
							{name: "S3_BUCKET", value: #config.backup.s3.bucket},
							{name: "MC_CONFIG_DIR", value: "/tmp/.mc"},
							if #config.backup.s3.credentialsFromPodIdentity {
								name:  "AWS_REGION"
								value: #config.backup.s3.region
							},
							if #config.backup.s3.credentialsFromPodIdentity {
								name:  "AWS_DEFAULT_REGION"
								value: #config.backup.s3.region
							},
							if !#config.backup.s3.credentialsFromPodIdentity {
								name: "S3_ACCESS_KEY"
								valueFrom: secretKeyRef: {
									name: #config._backupSecretName
									key:  #config.backup.s3.existingSecretAccessKeyKey
								}
							},
							if !#config.backup.s3.credentialsFromPodIdentity {
								name: "S3_SECRET_KEY"
								valueFrom: secretKeyRef: {
									name: #config._backupSecretName
									key:  #config.backup.s3.existingSecretSecretKeyKey
								}
							},
						]
						volumeMounts: [
							{name: "backup-staging", mountPath: "/backup", readOnly: true},
							{name: "backup-tmp", mountPath: "/tmp"},
						]
						if len(#config.backup.resources) > 0 {
							resources: #config.backup.resources
						}
						securityContext: #config.securityContext
					}]
					volumes: [
						{name: "data", persistentVolumeClaim: claimName: #config._pvcName},
						{name: "backup-staging", emptyDir: sizeLimit: #config.backup.scratchSizeLimit},
						{name: "backup-tmp", emptyDir: sizeLimit: #config.backup.tmpSizeLimit},
					]
				}
			}
		}
	}
}
