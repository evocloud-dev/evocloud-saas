package templates

import (
	corev1 "k8s.io/api/core/v1"
	batchv1 "k8s.io/api/batch/v1"
)

#BackupConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-backup-scripts"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: {
		"mongo-backup.sh": """
			#!/bin/sh
			set -eu
			timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
			archive="/backup/out/${BACKUP_ARCHIVE_PREFIX}-mongodb-${timestamp}.gz"
			mkdir -p /backup/out
			echo "Running mongodump to ${archive}..."
			mongodump --uri="${MONGODB_URI}" --archive="${archive}" --gzip
			printf "%s" "${archive}" > /backup/out/backup-file
			echo "Mongodump complete: ${archive}"
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
			echo "Upload complete: $(basename "${archive}")"
			"""
	}
}

#BackupCronJob: batchv1.#CronJob & {
	#config: #Config
	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(#config.metadata.name)-backup"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: batchv1.#CronJobSpec & {
		schedule:                   #config.backup.schedule
		suspend:                    #config.backup.suspend
		concurrencyPolicy:          #config.backup.concurrencyPolicy
		successfulJobsHistoryLimit: #config.backup.successfulJobsHistoryLimit
		failedJobsHistoryLimit:     #config.backup.failedJobsHistoryLimit
		jobTemplate: batchv1.#JobTemplateSpec & {
			spec: {
				backoffLimit: #config.backup.backoffLimit
				template: {
					metadata: labels: {
						"app.kubernetes.io/name":     "opensign-backup"
						"app.kubernetes.io/instance": #config.metadata.name
					}
					spec: corev1.#PodSpec & {
						restartPolicy: "Never"
						serviceAccountName: [
							if #config.server.serviceAccount.name != "" {#config.server.serviceAccount.name},
							"\(#config.metadata.name)-server",
						][0]
						securityContext: {
							runAsNonRoot: true
							runAsUser:    999
							runAsGroup:   999
							fsGroup:      999
							seccompProfile: type: "RuntimeDefault"
						}
						initContainers: [{
							name:            "dump"
							image:           #config.backup.images.mongodb
							imagePullPolicy: "IfNotPresent"
							command: ["/bin/sh", "/scripts/mongo-backup.sh"]
							env: [
								{
									name:  "BACKUP_ARCHIVE_PREFIX"
									value: #config.backup.archivePrefix
								},
								if #config.externalMongodb.enabled && #config.externalMongodb.existingSecret != "" {
									name: "MONGODB_URI"
									valueFrom: secretKeyRef: {
										name: #config.externalMongodb.existingSecret
										key: [
											if #config.externalMongodb.existingSecretUriKey != "" {#config.externalMongodb.existingSecretUriKey},
											#config.externalMongodb.existingSecretKey,
										][0]
									}
								},
								if !(#config.externalMongodb.enabled && #config.externalMongodb.existingSecret != "") {
									name: "MONGODB_URI"
									value: [
										if #config.externalMongodb.enabled && #config.externalMongodb.uri != "" {
											#config.externalMongodb.uri
										},
										"mongodb://\(#config.metadata.name)-mongo:\(#config.mongodb.port)/opensign",
									][0]
								},
							]
							securityContext: {
								allowPrivilegeEscalation: false
								capabilities: drop: ["ALL"]
								readOnlyRootFilesystem: false
							}
							volumeMounts: [
								{name: "scripts", mountPath: "/scripts"},
								{name: "backup-out", mountPath: "/backup/out"},
							]
						}]
						containers: [{
							name:            "uploader"
							image:           #config.backup.images.uploader
							imagePullPolicy: "IfNotPresent"
							command: ["/bin/sh", "/scripts/upload-backup.sh"]
							env: [
								{name: "S3_ENDPOINT", value: #config.backup.s3.endpoint},
								{name: "S3_BUCKET", value: #config.backup.s3.bucket},
								{name: "S3_PREFIX", value: #config.backup.s3.prefix},
								{name: "S3_CREATE_BUCKET_IF_NOT_EXISTS", value: "\(#config.backup.s3.createBucketIfNotExists)"},
								if #config.backup.s3.existingSecret != "" {
									name: "S3_ACCESS_KEY"
									valueFrom: secretKeyRef: {
										name: #config.backup.s3.existingSecret
										key:  #config.backup.s3.existingSecretAccessKeyKey
									}
								},
								if #config.backup.s3.existingSecret == "" {
									name:  "S3_ACCESS_KEY"
									value: #config.backup.s3.accessKey
								},
								if #config.backup.s3.existingSecret != "" {
									name: "S3_SECRET_KEY"
									valueFrom: secretKeyRef: {
										name: #config.backup.s3.existingSecret
										key:  #config.backup.s3.existingSecretSecretKeyKey
									}
								},
								if #config.backup.s3.existingSecret == "" {
									name:  "S3_SECRET_KEY"
									value: #config.backup.s3.secretKey
								},
							]
							resources: #config.backup.resources
							securityContext: {
								allowPrivilegeEscalation: false
								capabilities: drop: ["ALL"]
								readOnlyRootFilesystem: false
							}
							volumeMounts: [
								{name: "scripts", mountPath: "/scripts"},
								{name: "backup-out", mountPath: "/backup/out"},
							]
						}]
						volumes: [
							{
								name: "scripts"
								configMap: {
									name:        "\(#config.metadata.name)-backup-scripts"
									defaultMode: 0o755
								}
							},
							{
								name: "backup-out"
								emptyDir: {}
							},
						]
					}
				}
			}
		}
	}
}
