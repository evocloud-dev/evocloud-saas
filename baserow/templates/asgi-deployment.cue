package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	"list"
)

#DeploymentAsgi: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-asgi"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		if !#config.backend.asgi.autoscaling.enabled {
			replicas: #config.backend.asgi.replicaCount
		}
		revisionHistoryLimit: #config.backend.asgi.revisionHistoryLimit
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-asgi"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				if #config.backend.asgi.podAnnotations != _|_ {
					annotations: #config.backend.asgi.podAnnotations
				}
				labels: {
					"app.kubernetes.io/name":     "\(#config.metadata.name)-asgi"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: {
				automountServiceAccountToken: false
				if len(#config.backend.asgi.imagePullSecrets) > 0 {
					imagePullSecrets: #config.backend.asgi.imagePullSecrets
				}
				if #config.backend.asgi.serviceAccount.create {
					if #config.backend.asgi.serviceAccount.name != "" {
						serviceAccountName: #config.backend.asgi.serviceAccount.name
					}
					if #config.backend.asgi.serviceAccount.name == "" {
						serviceAccountName: "\(#config.metadata.name)-asgi"
					}
				}
				if !#config.backend.asgi.serviceAccount.create {
					if #config.backend.asgi.serviceAccount.name != "" {
						serviceAccountName: #config.backend.asgi.serviceAccount.name
					}
					if #config.backend.asgi.serviceAccount.name == "" {
						serviceAccountName: "default"
					}
				}
				if #config.backend.asgi.podSecurityContext != _|_ {
					securityContext: #config.backend.asgi.podSecurityContext
				}
				containers: [
					{
						name:            "asgi"
						image:           "\(#config.backend.asgi.image.registry)/\(#config.backend.asgi.image.repository):\(#config.backend.asgi.image.tag)"
						imagePullPolicy: #config.backend.asgi.image.pullPolicy
						workingDir:      "/baserow"
						args: [
							"gunicorn",
						]
						_envLists: [
							[
								// Baserow Backend Settings
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
								// Baserow Email Settings
								if #config.backend.config.email.smtp != _|_ {
									{
										name: "EMAIL_SMTP_PASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-email"
											key:  "email-password"
										}
									}
								},
								// Baserow File Upload Settings
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
								// Database Settings
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
								// Redis Settings
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
							#config.backend.asgi.extraEnv,
						]
						env: list.Concat(_envLists)
						envFrom: [
							{
								configMapRef: name: "\(#config.metadata.name)"
							},
							{
								configMapRef: name: "\(#config.metadata.name)-backend"
							},
						]
						ports: [
							{
								name:          "http"
								containerPort: #config.backend.asgi.service.port
								protocol:      "TCP"
							},
						]
						if #config.backend.asgi.livenessProbe != _|_ {
							livenessProbe: {
								exec: command: [
									"/bin/bash",
									"-c",
									"/baserow/backend/docker/docker-entrypoint.sh backend-healthcheck",
								]
								if #config.backend.asgi.livenessProbe.failureThreshold != _|_ {
									failureThreshold: #config.backend.asgi.livenessProbe.failureThreshold
								}
								if #config.backend.asgi.livenessProbe.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.backend.asgi.livenessProbe.initialDelaySeconds
								}
								if #config.backend.asgi.livenessProbe.periodSeconds != _|_ {
									periodSeconds: #config.backend.asgi.livenessProbe.periodSeconds
								}
								if #config.backend.asgi.livenessProbe.timeoutSeconds != _|_ {
									timeoutSeconds: #config.backend.asgi.livenessProbe.timeoutSeconds
								}
								if #config.backend.asgi.livenessProbe.successThreshold != _|_ {
									successThreshold: #config.backend.asgi.livenessProbe.successThreshold
								}
							}
						}
						if #config.backend.asgi.readinessProbe != _|_ {
							readinessProbe: {
								exec: command: [
									"/bin/bash",
									"-c",
									"/baserow/backend/docker/docker-entrypoint.sh backend-healthcheck",
								]
								if #config.backend.asgi.readinessProbe.failureThreshold != _|_ {
									failureThreshold: #config.backend.asgi.readinessProbe.failureThreshold
								}
								if #config.backend.asgi.readinessProbe.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.backend.asgi.readinessProbe.initialDelaySeconds
								}
								if #config.backend.asgi.readinessProbe.periodSeconds != _|_ {
									periodSeconds: #config.backend.asgi.readinessProbe.periodSeconds
								}
								if #config.backend.asgi.readinessProbe.timeoutSeconds != _|_ {
									timeoutSeconds: #config.backend.asgi.readinessProbe.timeoutSeconds
								}
								if #config.backend.asgi.readinessProbe.successThreshold != _|_ {
									successThreshold: #config.backend.asgi.readinessProbe.successThreshold
								}
							}
						}
						if #config.backend.asgi.resources != _|_ {
							resources: #config.backend.asgi.resources
						}
						if #config.backend.asgi.securityContext != _|_ {
							securityContext: #config.backend.asgi.securityContext
						}
						if #config.backend.persistence.enabled {
							volumeMounts: [
								{
									name:      "media"
									mountPath: "/baserow/media" // or use #config.backend.config.media.root if mapped
								},
							]
						}
					},
				]
				if #config.backend.asgi.priorityClassName != "" {
					priorityClassName: #config.backend.asgi.priorityClassName
				}
				if #config.backend.asgi.nodeSelector != _|_ {
					nodeSelector: #config.backend.asgi.nodeSelector
				}
				if #config.backend.asgi.affinity != _|_ {
					affinity: #config.backend.asgi.affinity
				}
				if len(#config.backend.asgi.tolerations) > 0 {
					tolerations: #config.backend.asgi.tolerations
				}
				if #config.backend.persistence.enabled {
					volumes: [
						{
							name: "media"
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-media"
						},
					]
				}
			}
		}
	}
}
