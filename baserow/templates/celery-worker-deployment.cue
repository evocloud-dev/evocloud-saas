package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	"list"
)

#DeploymentCeleryWorker: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-celery-worker"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-celery-worker"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
		if !#config.backend.celery.worker.autoscaling.enabled {
			replicas: #config.backend.celery.worker.replicaCount
		}
		revisionHistoryLimit: #config.backend.celery.worker.revisionHistoryLimit
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-celery-worker"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				if #config.backend.celery.worker.podAnnotations != _|_ {
					annotations: #config.backend.celery.worker.podAnnotations
				}
				labels: {
					"app.kubernetes.io/name":     "\(#config.metadata.name)-celery-worker"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: {
				automountServiceAccountToken: false
				if len(#config.backend.celery.worker.imagePullSecrets) > 0 {
					imagePullSecrets: #config.backend.celery.worker.imagePullSecrets
				}
				if #config.backend.celery.worker.serviceAccount.create {
					if #config.backend.celery.worker.serviceAccount.name != "" {
						serviceAccountName: #config.backend.celery.worker.serviceAccount.name
					}
					if #config.backend.celery.worker.serviceAccount.name == "" {
						serviceAccountName: "\(#config.metadata.name)-celery"
					}
				}
				if !#config.backend.celery.worker.serviceAccount.create {
					if #config.backend.celery.worker.serviceAccount.name != "" {
						serviceAccountName: #config.backend.celery.worker.serviceAccount.name
					}
					if #config.backend.celery.worker.serviceAccount.name == "" {
						serviceAccountName: "default"
					}
				}
				if #config.backend.celery.worker.podSecurityContext != _|_ {
					securityContext: #config.backend.celery.worker.podSecurityContext
				}
				containers: [
					{
						name:            "celery-worker"
						image:           "\(#config.backend.celery.worker.image.registry)/\(#config.backend.celery.worker.image.repository):\(#config.backend.celery.worker.image.tag)"
						imagePullPolicy: #config.backend.celery.worker.image.pullPolicy
						args: [
							"celery-worker",
						]
						_envListsWorker: [
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
							#config.backend.celery.worker.extraEnv,
						]
						env: list.Concat(_envListsWorker)
						envFrom: [
							{
								configMapRef: name: "\(#config.metadata.name)"
							},
							{
								configMapRef: name: "\(#config.metadata.name)-backend"
							},
						]
						if #config.backend.celery.worker.livenessProbe != _|_ {
							livenessProbe: {
								exec: command: [
									"/bin/bash",
									"-c",
									"/baserow/backend/docker/docker-entrypoint.sh celery-worker-healthcheck",
								]
								if #config.backend.celery.worker.livenessProbe.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.backend.celery.worker.livenessProbe.initialDelaySeconds
								}
								if #config.backend.celery.worker.livenessProbe.timeoutSeconds != _|_ {
									timeoutSeconds: #config.backend.celery.worker.livenessProbe.timeoutSeconds
								}
								if #config.backend.celery.worker.livenessProbe.periodSeconds != _|_ {
									periodSeconds: #config.backend.celery.worker.livenessProbe.periodSeconds
								}
								if #config.backend.celery.worker.livenessProbe.failureThreshold != _|_ {
									failureThreshold: #config.backend.celery.worker.livenessProbe.failureThreshold
								}
							}
						}
						if #config.backend.celery.worker.readinessProbe != _|_ {
							readinessProbe: {
								exec: command: [
									"/bin/bash",
									"-c",
									"/baserow/backend/docker/docker-entrypoint.sh celery-worker-healthcheck",
								]
								if #config.backend.celery.worker.readinessProbe.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.backend.celery.worker.readinessProbe.initialDelaySeconds
								}
								if #config.backend.celery.worker.readinessProbe.timeoutSeconds != _|_ {
									timeoutSeconds: #config.backend.celery.worker.readinessProbe.timeoutSeconds
								}
								if #config.backend.celery.worker.readinessProbe.periodSeconds != _|_ {
									periodSeconds: #config.backend.celery.worker.readinessProbe.periodSeconds
								}
								if #config.backend.celery.worker.readinessProbe.failureThreshold != _|_ {
									failureThreshold: #config.backend.celery.worker.readinessProbe.failureThreshold
								}
							}
						}
						if #config.backend.celery.worker.resources != _|_ {
							resources: #config.backend.celery.worker.resources
						}
						if #config.backend.celery.worker.securityContext != _|_ {
							securityContext: #config.backend.celery.worker.securityContext
						}
					},
				]
				if #config.backend.celery.worker.priorityClassName != "" {
					priorityClassName: #config.backend.celery.worker.priorityClassName
				}
				if #config.backend.celery.worker.nodeSelector != _|_ {
					nodeSelector: #config.backend.celery.worker.nodeSelector
				}
				if #config.backend.celery.worker.affinity != _|_ {
					affinity: #config.backend.celery.worker.affinity
				}
				if len(#config.backend.celery.worker.tolerations) > 0 {
					tolerations: #config.backend.celery.worker.tolerations
				}
			}
		}
	}
}
