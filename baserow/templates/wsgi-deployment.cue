package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	"list"
)

#DeploymentWsgi: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-wsgi"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		if !#config.backend.wsgi.autoscaling.enabled {
			replicas: #config.backend.wsgi.replicaCount
		}
		revisionHistoryLimit: #config.backend.wsgi.revisionHistoryLimit
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-wsgi"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				if #config.backend.wsgi.podAnnotations != _|_ {
					annotations: #config.backend.wsgi.podAnnotations
				}
				labels: {
					"app.kubernetes.io/name":     "\(#config.metadata.name)-wsgi"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: {
				automountServiceAccountToken: false
				if len(#config.backend.wsgi.imagePullSecrets) > 0 {
					imagePullSecrets: #config.backend.wsgi.imagePullSecrets
				}
				if #config.backend.wsgi.serviceAccount.create {
					if #config.backend.wsgi.serviceAccount.name != "" {
						serviceAccountName: #config.backend.wsgi.serviceAccount.name
					}
					if #config.backend.wsgi.serviceAccount.name == "" {
						serviceAccountName: "\(#config.metadata.name)-wsgi"
					}
				}
				if !#config.backend.wsgi.serviceAccount.create {
					if #config.backend.wsgi.serviceAccount.name != "" {
						serviceAccountName: #config.backend.wsgi.serviceAccount.name
					}
					if #config.backend.wsgi.serviceAccount.name == "" {
						serviceAccountName: "default"
					}
				}
				if #config.backend.wsgi.podSecurityContext != _|_ {
					securityContext: #config.backend.wsgi.podSecurityContext
				}
				containers: [
					{
						name:            "wsgi"
						image:           "\(#config.backend.wsgi.image.registry)/\(#config.backend.wsgi.image.repository):\(#config.backend.wsgi.image.tag)"
						imagePullPolicy: #config.backend.wsgi.image.pullPolicy
						workingDir:      "/baserow"
						args: [
							"gunicorn-wsgi",
							"--timeout",
							"120",
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
							#config.backend.wsgi.extraEnv,
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
								containerPort: #config.backend.wsgi.service.port
								protocol:      "TCP"
							},
						]
						if #config.backend.wsgi.livenessProbe != _|_ {
							livenessProbe: {
								exec: command: [
									"/bin/bash",
									"-c",
									"/baserow/backend/docker/docker-entrypoint.sh backend-healthcheck",
								]
								if #config.backend.wsgi.livenessProbe.failureThreshold != _|_ {
									failureThreshold: #config.backend.wsgi.livenessProbe.failureThreshold
								}
								if #config.backend.wsgi.livenessProbe.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.backend.wsgi.livenessProbe.initialDelaySeconds
								}
								if #config.backend.wsgi.livenessProbe.periodSeconds != _|_ {
									periodSeconds: #config.backend.wsgi.livenessProbe.periodSeconds
								}
								if #config.backend.wsgi.livenessProbe.timeoutSeconds != _|_ {
									timeoutSeconds: #config.backend.wsgi.livenessProbe.timeoutSeconds
								}
								if #config.backend.wsgi.livenessProbe.successThreshold != _|_ {
									successThreshold: #config.backend.wsgi.livenessProbe.successThreshold
								}
							}
						}
						if #config.backend.wsgi.readinessProbe != _|_ {
							readinessProbe: {
								exec: command: [
									"/bin/bash",
									"-c",
									"/baserow/backend/docker/docker-entrypoint.sh backend-healthcheck",
								]
								if #config.backend.wsgi.readinessProbe.failureThreshold != _|_ {
									failureThreshold: #config.backend.wsgi.readinessProbe.failureThreshold
								}
								if #config.backend.wsgi.readinessProbe.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.backend.wsgi.readinessProbe.initialDelaySeconds
								}
								if #config.backend.wsgi.readinessProbe.periodSeconds != _|_ {
									periodSeconds: #config.backend.wsgi.readinessProbe.periodSeconds
								}
								if #config.backend.wsgi.readinessProbe.timeoutSeconds != _|_ {
									timeoutSeconds: #config.backend.wsgi.readinessProbe.timeoutSeconds
								}
								if #config.backend.wsgi.readinessProbe.successThreshold != _|_ {
									successThreshold: #config.backend.wsgi.readinessProbe.successThreshold
								}
							}
						}
						if #config.backend.wsgi.resources != _|_ {
							resources: #config.backend.wsgi.resources
						}
						if #config.backend.wsgi.securityContext != _|_ {
							securityContext: #config.backend.wsgi.securityContext
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
				if #config.backend.wsgi.priorityClassName != "" {
					priorityClassName: #config.backend.wsgi.priorityClassName
				}
				if #config.backend.wsgi.nodeSelector != _|_ {
					nodeSelector: #config.backend.wsgi.nodeSelector
				}
				if #config.backend.wsgi.affinity != _|_ {
					affinity: #config.backend.wsgi.affinity
				}
				if len(#config.backend.wsgi.tolerations) > 0 {
					tolerations: #config.backend.wsgi.tolerations
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
