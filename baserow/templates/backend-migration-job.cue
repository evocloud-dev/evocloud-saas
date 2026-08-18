package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	"list"
)

#BackendMigrationJob: batchv1.#Job & {
	#config:    #Config
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-backend-migration"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-backend-migration"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     "\(#config.metadata.name)-backend-migration"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: {
				automountServiceAccountToken: false
				restartPolicy: "OnFailure"
				if #config.migration.priorityClassName != "" {
					priorityClassName: #config.migration.priorityClassName
				}
				if #config.migration.affinity != _|_ {
					affinity: #config.migration.affinity
				}
				if #config.migration.nodeSelector != _|_ {
					nodeSelector: #config.migration.nodeSelector
				}
				if len(#config.migration.tolerations) > 0 {
					tolerations: #config.migration.tolerations
				}
				if len(#config.migration.imagePullSecrets) > 0 {
					imagePullSecrets: #config.migration.imagePullSecrets
				}
				if len(#config.migration.volumes) > 0 {
					volumes: #config.migration.volumes
				}
				if #config.migration.securityContext.enabled {
					securityContext: {
						if #config.migration.securityContext.fsGroup != "" {
							fsGroup: #config.migration.securityContext.fsGroup
						}
						if #config.migration.securityContext.fsGroupChangePolicy != "" {
							fsGroupChangePolicy: #config.migration.securityContext.fsGroupChangePolicy
						}
						if #config.migration.securityContext.supplementalGroups != "" {
							supplementalGroups: #config.migration.securityContext.supplementalGroups
						}
					}
				}
				containers: [
					{
						name:            "migration"
						image:           "\(#config.migration.image.registry)/\(#config.migration.image.repository):\(#config.migration.image.tag)"
						imagePullPolicy: #config.migration.image.pullPolicy
						workingDir:      "/baserow"
						args: [
							"setup",
						]
						if #config.migration.containerSecurityContext.enabled {
							securityContext: {
								if #config.migration.containerSecurityContext.runAsUser != "" {
									runAsUser: #config.migration.containerSecurityContext.runAsUser
								}
								if #config.migration.containerSecurityContext.runAsGroup != "" {
									runAsGroup: #config.migration.containerSecurityContext.runAsGroup
								}
								if #config.migration.containerSecurityContext.runAsNonRoot != "" {
									runAsNonRoot: #config.migration.containerSecurityContext.runAsNonRoot
								}
								privileged: #config.migration.containerSecurityContext.privileged
								readOnlyRootFilesystem: #config.migration.containerSecurityContext.readOnlyRootFilesystem
								allowPrivilegeEscalation: #config.migration.containerSecurityContext.allowPrivilegeEscalation
								if len(#config.migration.containerSecurityContext.capabilities.add) > 0 || len(#config.migration.containerSecurityContext.capabilities.drop) > 0 {
									capabilities: {
										if len(#config.migration.containerSecurityContext.capabilities.add) > 0 {
											add: #config.migration.containerSecurityContext.capabilities.add
										}
										if len(#config.migration.containerSecurityContext.capabilities.drop) > 0 {
											drop: #config.migration.containerSecurityContext.capabilities.drop
										}
									}
								}
								if #config.migration.containerSecurityContext.seccompProfile.type != "" {
									seccompProfile: {
										type: #config.migration.containerSecurityContext.seccompProfile.type
									}
								}
							}
						}
						if len(#config.migration.volumeMounts) > 0 {
							volumeMounts: #config.migration.volumeMounts
						}
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
					},
				]
			}
		}
	}
}
