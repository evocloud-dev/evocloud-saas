package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	"list"
)

#DeploymentCeleryExportWorker: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-celery-export-worker"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-celery-export-worker"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
		if !#config.backend.celery.exportWorker.autoscaling.enabled {
			replicas: #config.backend.celery.exportWorker.replicaCount
		}
		revisionHistoryLimit: #config.backend.celery.exportWorker.revisionHistoryLimit
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-celery-export-worker"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				if #config.backend.celery.exportWorker.podAnnotations != _|_ {
					annotations: #config.backend.celery.exportWorker.podAnnotations
				}
				labels: {
					"app.kubernetes.io/name":     "\(#config.metadata.name)-celery-export-worker"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: {
				automountServiceAccountToken: false
				if len(#config.backend.celery.exportWorker.imagePullSecrets) > 0 {
					imagePullSecrets: #config.backend.celery.exportWorker.imagePullSecrets
				}
				if #config.backend.celery.exportWorker.serviceAccount.create {
					if #config.backend.celery.exportWorker.serviceAccount.name != "" {
						serviceAccountName: #config.backend.celery.exportWorker.serviceAccount.name
					}
					if #config.backend.celery.exportWorker.serviceAccount.name == "" {
						serviceAccountName: "\(#config.metadata.name)-celery"
					}
				}
				if !#config.backend.celery.exportWorker.serviceAccount.create {
					if #config.backend.celery.exportWorker.serviceAccount.name != "" {
						serviceAccountName: #config.backend.celery.exportWorker.serviceAccount.name
					}
					if #config.backend.celery.exportWorker.serviceAccount.name == "" {
						serviceAccountName: "default"
					}
				}
				if #config.backend.celery.exportWorker.podSecurityContext != _|_ {
					securityContext: #config.backend.celery.exportWorker.podSecurityContext
				}
				containers: [
					{
						name:            "celery-export-worker"
						image:           "\(#config.backend.celery.exportWorker.image.registry)/\(#config.backend.celery.exportWorker.image.repository):\(#config.backend.celery.exportWorker.image.tag)"
						imagePullPolicy: #config.backend.celery.exportWorker.image.pullPolicy
						args: [
							"celery-exportworker",
						]
						_envListsExport: [
							[
								{
									name: "BASEROW_JWT_SIGNING_KEY"
									valueFrom: secretKeyRef: {
										name: "\(#config.metadata.name)-backend"
										key:  "jwt-signing-key"
									}
								},
								{
									name: "SECRET_KEY"
									valueFrom: secretKeyRef: {
										name: "\(#config.metadata.name)-backend"
										key:  "secret-key"
									}
								},
								if #config.backend.config.email.smtp != _|_ {
									{
										name: "EMAIL_SMTP_PASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-email"
											key:  "email-password"
										}
									}
								},
								if #config.backend.config.aws.accessKeyId != _|_ || #config.backend.config.aws.existingSecret != _|_ {
									{
										name: "AWS_ACCESS_KEY_ID"
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-aws"
											key:  "access-key-id"
										}
									}
								},
								if #config.backend.config.aws.accessKeyId != _|_ || #config.backend.config.aws.existingSecret != _|_ {
									{
										name: "AWS_SECRET_ACCESS_KEY"
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-aws"
											key:  "secret-access-key"
										}
									}
								},
								if #config.externalPostgresql.auth.userUsernameKey != "" {
									{
										name: "DATABASE_USER"
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-postgresql"
											key:  #config.externalPostgresql.auth.userUsernameKey
										}
									}
								},
								{
									name: "DATABASE_PASSWORD"
									valueFrom: secretKeyRef: {
										name: "\(#config.metadata.name)-postgresql"
										if #config.postgresql.enabled {
											key: "password"
										}
										if !#config.postgresql.enabled {
											key: #config.externalPostgresql.auth.userPasswordKey
										}
									}
								},
								if #config.redis.auth.enabled || #config.externalRedis.auth.enabled {
									{
										name: "REDIS_PASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-redis"
											if #config.redis.enabled {
												key: "password"
											}
											if !#config.redis.enabled {
												key: #config.externalRedis.auth.userPasswordKey
											}
										}
									}
								},
							],
							#config.#OtelEnv,
							#config.backend.celery.exportWorker.extraEnv,
						]
						env: list.Concat(_envListsExport)
						envFrom: [
							{
								configMapRef: name: "\(#config.metadata.name)"
							},
							{
								configMapRef: name: "\(#config.metadata.name)-backend"
							},
						]
						if #config.backend.celery.exportWorker.livenessProbe != _|_ {
							livenessProbe: {
								exec: command: [
									"/bin/bash",
									"-c",
									"/baserow/backend/docker/docker-entrypoint.sh celery-exportworker-healthcheck",
								]
								if #config.backend.celery.exportWorker.livenessProbe.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.backend.celery.exportWorker.livenessProbe.initialDelaySeconds
								}
								if #config.backend.celery.exportWorker.livenessProbe.timeoutSeconds != _|_ {
									timeoutSeconds: #config.backend.celery.exportWorker.livenessProbe.timeoutSeconds
								}
								if #config.backend.celery.exportWorker.livenessProbe.periodSeconds != _|_ {
									periodSeconds: #config.backend.celery.exportWorker.livenessProbe.periodSeconds
								}
								if #config.backend.celery.exportWorker.livenessProbe.failureThreshold != _|_ {
									failureThreshold: #config.backend.celery.exportWorker.livenessProbe.failureThreshold
								}
							}
						}
						if #config.backend.celery.exportWorker.readinessProbe != _|_ {
							readinessProbe: {
								exec: command: [
									"/bin/bash",
									"-c",
									"/baserow/backend/docker/docker-entrypoint.sh celery-exportworker-healthcheck",
								]
								if #config.backend.celery.exportWorker.readinessProbe.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.backend.celery.exportWorker.readinessProbe.initialDelaySeconds
								}
								if #config.backend.celery.exportWorker.readinessProbe.timeoutSeconds != _|_ {
									timeoutSeconds: #config.backend.celery.exportWorker.readinessProbe.timeoutSeconds
								}
								if #config.backend.celery.exportWorker.readinessProbe.periodSeconds != _|_ {
									periodSeconds: #config.backend.celery.exportWorker.readinessProbe.periodSeconds
								}
								if #config.backend.celery.exportWorker.readinessProbe.failureThreshold != _|_ {
									failureThreshold: #config.backend.celery.exportWorker.readinessProbe.failureThreshold
								}
							}
						}
						if #config.backend.celery.exportWorker.resources != _|_ {
							resources: #config.backend.celery.exportWorker.resources
						}
						if #config.backend.celery.exportWorker.securityContext != _|_ {
							securityContext: #config.backend.celery.exportWorker.securityContext
						}
					},
				]
				if #config.backend.celery.exportWorker.priorityClassName != "" {
					priorityClassName: #config.backend.celery.exportWorker.priorityClassName
				}
				if #config.backend.celery.exportWorker.nodeSelector != _|_ {
					nodeSelector: #config.backend.celery.exportWorker.nodeSelector
				}
				if #config.backend.celery.exportWorker.affinity != _|_ {
					affinity: #config.backend.celery.exportWorker.affinity
				}
				if len(#config.backend.celery.exportWorker.tolerations) > 0 {
					tolerations: #config.backend.celery.exportWorker.tolerations
				}
			}
		}
	}
}
