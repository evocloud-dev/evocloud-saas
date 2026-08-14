package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	"list"
)

#DeploymentCeleryFlower: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-celery-flower"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-celery-flower"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
		replicas: #config.backend.celery.flower.replicaCount
		revisionHistoryLimit: #config.backend.celery.flower.revisionHistoryLimit
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-celery-flower"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				if #config.backend.celery.flower.podAnnotations != _|_ {
					annotations: #config.backend.celery.flower.podAnnotations
				}
				labels: {
					"app.kubernetes.io/name":     "\(#config.metadata.name)-celery-flower"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: {
				automountServiceAccountToken: false
				if len(#config.backend.celery.flower.imagePullSecrets) > 0 {
					imagePullSecrets: #config.backend.celery.flower.imagePullSecrets
				}
				if #config.backend.celery.flower.serviceAccount.create {
					if #config.backend.celery.flower.serviceAccount.name != "" {
						serviceAccountName: #config.backend.celery.flower.serviceAccount.name
					}
					if #config.backend.celery.flower.serviceAccount.name == "" {
						serviceAccountName: "\(#config.metadata.name)-celery"
					}
				}
				if !#config.backend.celery.flower.serviceAccount.create {
					if #config.backend.celery.flower.serviceAccount.name != "" {
						serviceAccountName: #config.backend.celery.flower.serviceAccount.name
					}
					if #config.backend.celery.flower.serviceAccount.name == "" {
						serviceAccountName: "default"
					}
				}
				if #config.backend.celery.flower.podSecurityContext != _|_ {
					securityContext: #config.backend.celery.flower.podSecurityContext
				}
				containers: [
					{
						name:            "celery-flower"
						image:           "\(#config.backend.celery.flower.image.registry)/\(#config.backend.celery.flower.image.repository):\(#config.backend.celery.flower.image.tag)"
						imagePullPolicy: #config.backend.celery.flower.image.pullPolicy
						args: [
							"celery-flower",
						]
						ports: [
							{
								name:          "http"
								containerPort: #config.backend.celery.flower.service.targetPort
								protocol:      "TCP"
							},
						]
						_envListsFlower: [
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
								if #config.backend.config.aws.secretAccessKey != _|_ || #config.backend.config.aws.existingSecret != _|_ {
									{
										name: "AWS_SECRET_ACCESS_KEY"
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-aws"
											key:  "secret-access-key"
										}
									}
								},
								if #config.postgresql.enabled {
									{
										name: "DATABASE_PASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-postgresql"
											key:  "password"
										}
									}
								},
								if !#config.postgresql.enabled {
									{
										name: "DATABASE_PASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(#config.externalPostgresql.auth.existingSecret)"
											key:  "\(#config.externalPostgresql.auth.userPasswordKey)"
										}
									}
								},
								if #config.redis.enabled {
									{
										name: "REDIS_PASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-redis"
											key:  "password"
										}
									}
								},
								if !#config.redis.enabled {
									if #config.externalRedis.auth.enabled {
										{
											name: "REDIS_PASSWORD"
											valueFrom: secretKeyRef: {
												name: "\(#config.externalRedis.auth.existingSecret)"
												key:  "\(#config.externalRedis.auth.userPasswordKey)"
											}
										}
									}
								},
							],
							#config.backend.celery.flower.extraEnv,
							#config.OtelEnv,
						]
						env: list.Concat(_envListsFlower)
						envFrom: [
							{
								configMapRef: name: #config.metadata.name
							},
							{
								configMapRef: name: "\(#config.metadata.name)-backend"
							},
						]
						if #config.backend.celery.flower.resources != _|_ {
							resources: #config.backend.celery.flower.resources
						}
						if #config.backend.celery.flower.securityContext != _|_ {
							securityContext: #config.backend.celery.flower.securityContext
						}
					},
				]
				if #config.backend.celery.flower.priorityClassName != "" {
					priorityClassName: #config.backend.celery.flower.priorityClassName
				}
				if #config.backend.celery.flower.nodeSelector != _|_ {
					nodeSelector: #config.backend.celery.flower.nodeSelector
				}
				if #config.backend.celery.flower.affinity != _|_ {
					affinity: #config.backend.celery.flower.affinity
				}
				if len(#config.backend.celery.flower.tolerations) > 0 {
					tolerations: #config.backend.celery.flower.tolerations
				}
			}
		}
	}
}
