package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#WorkerDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name: "\(#config.metadata.name)-worker"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "worker"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		strategy: {
			type: "RollingUpdate"
			rollingUpdate: {
				maxSurge:       1
				maxUnavailable: 1
			}
		}
		replicas: #config.worker.replicaCount
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "worker"
		}
		template: {
			metadata: labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "worker"
			}
			spec: corev1.#PodSpec & {
				securityContext: {
					runAsUser: #config.securityContext.runAsUser
					fsGroup:   #config.securityContext.fsGroup
				}
				initContainers: [
					{
						name:  "wait-for-db"
						image: #config.utilityImages.postgres
						command: [
							"sh",
							"-c",
							"""
							until pg_isready -h \(#config.metadata.name)-db -p 5432 -U postgres; do
							  echo \"Waiting for database socket...\"
							  sleep 2
							done
							echo \"Database socket is ready!\"
							""",
						]
					},
				]
				containers: [
					{
						name:            "worker"
						image:           #config.worker.image.reference
						imagePullPolicy: #config.worker.image.pullPolicy
						command:         #config.worker.command
						stdin:           #config.worker.stdin
						tty:             #config.worker.tty
						env: [
							{
								name:  "SERVER_URL"
								value: #config.server.env.SERVER_URL
							},
							{
								name:  "FRONTEND_URL"
								value: #config.server.env.FRONTEND_URL
							},
							{
								name:  "REDIS_URL"
								value: "redis://\(#config.metadata.name)-redis:\(#config.redis.internal.service.port)"
							},
							if #config.db.internal.enabled {
								{
									name: "PG_DATABASE_URL"
									valueFrom: secretKeyRef: {
										name: "\(#config.metadata.name)-db-url"
										key:  "url"
									}
								}
							},
							if !#config.db.internal.enabled && #config.db.external != _|_ && #config.db.external.secretName != "" {
								{
									name: "DB_PASSWORD"
									valueFrom: secretKeyRef: {
										name: #config.db.external.secretName
										key:  #config.db.external.passwordKey
									}
								}
							},
							if !#config.db.internal.enabled && #config.db.external != _|_ && #config.db.external.secretName != "" {
								{
									name: "PG_DATABASE_URL"
									_ssl: *"" | string
									if #config.db.external.ssl {
										_ssl: "?sslmode=require"
									}
									value: "postgres://\(#config.db.external.user):$(DB_PASSWORD)@\(#config.db.external.host):\(#config.db.external.port)/\(#config.db.external.database)\(_ssl)"
								}
							},
							{
								name:  "STORAGE_TYPE"
								value: #config.storage.type
							},
							{
								name:  "IS_MULTIWORKSPACE_ENABLED"
								value: #config.server.env.IS_MULTIWORKSPACE_ENABLED
							},
							{
								name:  "DEFAULT_SUBDOMAIN"
								value: #config.server.env.DEFAULT_SUBDOMAIN
							},
							{
								name: "APP_SECRET"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-tokens"
									key:  "accessToken"
								}
							},
							if #config.storage.type == "s3" {
								{
									name:  "STORAGE_S3_NAME"
									value: #config.storage.s3.bucket
								}
							},
							if #config.storage.type == "s3" {
								{
									name:  "STORAGE_S3_REGION"
									value: #config.storage.s3.region
								}
							},
							if #config.storage.type == "s3" {
								{
									name:  "STORAGE_S3_ENDPOINT"
									value: #config.storage.s3.endpoint
								}
							},
							if #config.storage.type == "s3" {
								{
									name:  "STORAGE_S3_ACCESS_KEY_ID"
									value: #config.storage.s3.accessKeyId
								}
							},
							if #config.storage.type == "s3" {
								{
									name:  "STORAGE_S3_SECRET_ACCESS_KEY"
									value: #config.storage.s3.secretAccessKey
								}
							},
						]
						resources: #config.worker.resources
					},
				]
			}
		}
	}
}
