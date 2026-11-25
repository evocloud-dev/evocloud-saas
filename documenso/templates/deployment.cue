package templates

import (
	"list"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels:    #config.#labels
		if len(#config.#deploymentAnnotations) > 0 {
			annotations: #config.#deploymentAnnotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.autoscaling.enabled {
			replicas: #config.replicaCount
		}
		strategy: {
			if !#config.autoscaling.enabled && #config.replicaCount == 1 {
				type: "Recreate"
			}
			if #config.autoscaling.enabled || #config.replicaCount > 1 {
				type: "RollingUpdate"
				rollingUpdate: {
					maxSurge:       1
					maxUnavailable: 0
				}
			}
		}
		selector: matchLabels: #config.#selector
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: {
					for k, v in #config.#selector { "\(k)": v }
					for k, v in #config.podLabels { "\(k)": v }
				}
				if len(#config.podAnnotations) > 0 {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            #config.#serviceAccountName
				automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				securityContext:               #config.podSecurityContext
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				initContainers: list.Concat([
					[
						{
							name:            "wait-for-postgresql"
							image:           #config.#waitImage
							imagePullPolicy: #config.waitForServices.image.pullPolicy
							securityContext: {
								runAsNonRoot:             true
								runAsUser:                65534
								runAsGroup:               65534
								allowPrivilegeEscalation: false
								readOnlyRootFilesystem:   true
								capabilities: drop: ["ALL"]
							}
							resources: #config.waitForServices.resources
							command: ["sh", "-c"]
							args: [
								"timeout \(#config.waitForServices.timeoutSeconds) sh -c 'until nc -z -w 2 \"$1\" \"$2\"; do sleep 2; done' -- \(#config.#databaseHost) \(#config.#databasePort)",
							]
						},
					],
					[
						if #config.documenso.jobsProvider == "bullmq" {
							name:            "wait-for-redis"
							image:           #config.#waitImage
							imagePullPolicy: #config.waitForServices.image.pullPolicy
							securityContext: {
								runAsNonRoot:             true
								runAsUser:                65534
								runAsGroup:               65534
								allowPrivilegeEscalation: false
								readOnlyRootFilesystem:   true
								capabilities: drop: ["ALL"]
							}
							resources: #config.waitForServices.resources
							command: ["sh", "-c"]
							args: [
								"timeout \(#config.waitForServices.timeoutSeconds) sh -c 'until nc -z -w 2 \"$1\" \"$2\"; do sleep 2; done' -- \(#config.#redisHost) \(#config.#redisPort)",
							]
						},
					],
				])
				containers: [{
					name:            "documenso"
					image:           #config.#documensoImage
					imagePullPolicy: #config.image.pullPolicy
					securityContext: #config.securityContext
					ports: [{
						name:          "http"
						containerPort: 3000
						protocol:      "TCP"
					}]
					env: list.Concat([
						[
							{name: "NODE_ENV", value: "production"},
							{name: "PORT", value: "3000"},
							{name: "NEXT_PUBLIC_WEBAPP_URL", value: #config.#publicUrl},
							{name: "NEXTAUTH_URL", value: #config.#publicUrl},
							{name: "NEXT_PRIVATE_INTERNAL_WEBAPP_URL", value: "http://127.0.0.1:3000"},
							{name: "NEXT_PRIVATE_SMTP_FROM_ADDRESS", value: #config.documenso.mailFromAddress},
							{name: "NEXT_PRIVATE_SMTP_FROM_NAME", value: #config.documenso.mailFromName},
							{name: "NEXT_PRIVATE_JOBS_PROVIDER", value: #config.documenso.jobsProvider},
							{
								name: "NEXTAUTH_SECRET"
								valueFrom: secretKeyRef: {
									name: #config.#applicationSecretName
									key:  #config.documenso.nextAuthSecretKey
								}
							},
							{
								name: "NEXT_PRIVATE_ENCRYPTION_KEY"
								valueFrom: secretKeyRef: {
									name: #config.#applicationSecretName
									key:  #config.documenso.encryptionKeyKey
								}
							},
							{
								name: "NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY"
								valueFrom: secretKeyRef: {
									name: #config.#applicationSecretName
									key:  #config.documenso.encryptionSecondaryKeyKey
								}
							},
						],
						[
							if #config.database.external.enabled {
								name: "NEXT_PRIVATE_DATABASE_URL"
								valueFrom: secretKeyRef: {
									name: #config.#databaseSecretName
									key:  #config.database.external.urlKey
								}
							},
						],
						[
							if #config.database.external.enabled && #config.database.external.directUrlEnabled {
								name: "NEXT_PRIVATE_DIRECT_DATABASE_URL"
								valueFrom: secretKeyRef: {
									name: #config.#databaseSecretName
									key:  #config.database.external.directUrlKey
								}
							},
						],
						[
							if !#config.database.external.enabled {
								name: "DATABASE_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#databaseSecretName
									key:  #config.#databaseSecretKey
								}
							},
						],
						[
							if !#config.database.external.enabled {
								name:  "NEXT_PRIVATE_DATABASE_URL"
								value: "postgresql://\(#config.postgresql.auth.username):$(DATABASE_PASSWORD)@\(#config.#databaseHost):\(#config.#databasePort)/\(#config.postgresql.auth.database)?connect_timeout=300"
							},
						],
						[
							if !#config.database.external.enabled {
								name:  "NEXT_PRIVATE_DIRECT_DATABASE_URL"
								value: "postgresql://\(#config.postgresql.auth.username):$(DATABASE_PASSWORD)@\(#config.#databaseHost):\(#config.#databasePort)/\(#config.postgresql.auth.database)?connect_timeout=300"
							},
						],
						[
							if #config.documenso.jobsProvider == "bullmq" {
								name: "REDIS_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#redisSecretName
									key:  #config.#redisSecretKey
								}
							},
						],
						[
							if #config.documenso.jobsProvider == "bullmq" {
								name:  "NEXT_PRIVATE_REDIS_URL"
								value: "redis://:$(REDIS_PASSWORD)@\(#config.#redisHost):\(#config.#redisPort)/\(#config.redis.external.database)"
							},
						],
						[
							if #config.documenso.jobsProvider == "bullmq" {
								name:  "NEXT_PRIVATE_REDIS_PREFIX"
								value: "documenso"
							},
						],
						[
							if #config.smtp.enabled || #config.inbucket.enabled {
								name:  "NEXT_PRIVATE_SMTP_TRANSPORT"
								value: "smtp-auth"
							},
						],
						[
							if #config.smtp.enabled {
								name:  "NEXT_PRIVATE_SMTP_HOST"
								value: #config.smtp.host
							},
							if !#config.smtp.enabled && #config.inbucket.enabled {
								name:  "NEXT_PRIVATE_SMTP_HOST"
								value: "\(#config.#fullname)-inbucket"
							},
						],
						[
							if #config.smtp.enabled {
								name:  "NEXT_PRIVATE_SMTP_PORT"
								value: "\(#config.smtp.port)"
							},
							if !#config.smtp.enabled && #config.inbucket.enabled {
								name:  "NEXT_PRIVATE_SMTP_PORT"
								value: "\(#config.inbucket.service.smtpPort)"
							},
						],
						[
							if #config.smtp.enabled {
								name:  "NEXT_PRIVATE_SMTP_SECURE"
								value: "\(#config.smtp.secure)"
							},
							if !#config.smtp.enabled && #config.inbucket.enabled {
								name:  "NEXT_PRIVATE_SMTP_SECURE"
								value: "false"
							},
						],
						[
							if #config.smtp.enabled {
								name: "NEXT_PRIVATE_SMTP_USERNAME"
								valueFrom: secretKeyRef: {
									name: #config.smtp.existingSecret
									key:  #config.smtp.usernameKey
								}
							},
						],
						[
							if #config.smtp.enabled {
								name: "NEXT_PRIVATE_SMTP_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.smtp.existingSecret
									key:  #config.smtp.passwordKey
								}
							},
						],
						[
							if #config.objectStorage.provider == "s3" {
								name:  "NEXT_PUBLIC_UPLOAD_TRANSPORT"
								value: "s3"
							},
						],
						[
							if #config.objectStorage.provider == "s3" {
								name:  "NEXT_PRIVATE_UPLOAD_BUCKET"
								value: #config.objectStorage.s3.bucket
							},
						],
						[
							if #config.objectStorage.provider == "s3" {
								name:  "NEXT_PRIVATE_UPLOAD_REGION"
								value: #config.objectStorage.s3.region
							},
						],
						[
							if #config.objectStorage.provider == "s3" {
								name:  "NEXT_PRIVATE_UPLOAD_ENDPOINT"
								value: #config.objectStorage.s3.endpoint
							},
						],
						[
							if #config.objectStorage.provider == "s3" {
								name:  "NEXT_PRIVATE_UPLOAD_FORCE_PATH_STYLE"
								value: "\(#config.objectStorage.s3.forcePathStyle)"
							},
						],
						[
							if #config.objectStorage.provider == "s3" {
								name: "NEXT_PRIVATE_UPLOAD_ACCESS_KEY_ID"
								valueFrom: secretKeyRef: {
									name: #config.objectStorage.s3.existingSecret
									key:  #config.objectStorage.s3.accessKeyKey
								}
							},
						],
						[
							if #config.objectStorage.provider == "s3" {
								name: "NEXT_PRIVATE_UPLOAD_SECRET_ACCESS_KEY"
								valueFrom: secretKeyRef: {
									name: #config.objectStorage.s3.existingSecret
									key:  #config.objectStorage.s3.secretKeyKey
								}
							},
						],
						[
							if #config.certificate.enabled {
								name:  "NEXT_PRIVATE_SIGNING_TRANSPORT"
								value: "local"
							},
						],
						[
							if #config.certificate.enabled {
								name:  "NEXT_PRIVATE_SIGNING_LOCAL_FILE_PATH"
								value: #config.certificate.mountPath
							},
						],
						[
							if #config.certificate.enabled {
								name: "NEXT_PRIVATE_SIGNING_PASSPHRASE"
								valueFrom: secretKeyRef: {
									name: #config.certificate.existingSecret
									key:  #config.certificate.passphraseKey
								}
							},
						],
						[
							if #config.gotenberg.enabled {
								name:  "NEXT_PRIVATE_DOCUMENT_CONVERSION_URL"
								value: #config.gotenberg.url
							},
						],
						[
							if #config.gotenberg.enabled && #config.gotenberg.existingSecret != "" {
								name: "NEXT_PRIVATE_DOCUMENT_CONVERSION_USERNAME"
								valueFrom: secretKeyRef: {
									name: #config.gotenberg.existingSecret
									key:  #config.gotenberg.usernameKey
								}
							},
						],
						[
							if #config.gotenberg.enabled && #config.gotenberg.existingSecret != "" {
								name: "NEXT_PRIVATE_DOCUMENT_CONVERSION_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.gotenberg.existingSecret
									key:  #config.gotenberg.passwordKey
								}
							},
						],
						#config.documenso.extraEnv,
					])
					if len(#config.documenso.extraEnvFrom) > 0 {
						envFrom: #config.documenso.extraEnvFrom
					}
					if #config.probes.startup.enabled {
						startupProbe: {
							httpGet: {
								path: "/api/health"
								port: "http"
							}
							initialDelaySeconds: #config.probes.startup.initialDelaySeconds
							periodSeconds:       #config.probes.startup.periodSeconds
							timeoutSeconds:      #config.probes.startup.timeoutSeconds
							failureThreshold:    #config.probes.startup.failureThreshold
						}
					}
					if #config.probes.liveness.enabled {
						livenessProbe: {
							tcpSocket: port: "http"
							initialDelaySeconds: #config.probes.liveness.initialDelaySeconds
							periodSeconds:       #config.probes.liveness.periodSeconds
							timeoutSeconds:      #config.probes.liveness.timeoutSeconds
							failureThreshold:    #config.probes.liveness.failureThreshold
						}
					}
					if #config.probes.readiness.enabled {
						readinessProbe: {
							httpGet: {
								path: "/api/health"
								port: "http"
							}
							initialDelaySeconds: #config.probes.readiness.initialDelaySeconds
							periodSeconds:       #config.probes.readiness.periodSeconds
							timeoutSeconds:      #config.probes.readiness.timeoutSeconds
							failureThreshold:    #config.probes.readiness.failureThreshold
						}
					}
					resources: #config.resources
					volumeMounts: list.Concat([
						[
							{name: "runtime-tmp", mountPath: "/tmp"},
							{name: "npm-cache", mountPath: "/home/nodejs/.npm"},
						],
						[
							if #config.certificate.enabled {
								name:      "signing-certificate"
								mountPath: #config.certificate.mountPath
								subPath:   #config.certificate.fileKey
								readOnly:  true
							},
						],
						#config.extraVolumeMounts,
					])
				}]
				volumes: list.Concat([
					[
						{
							name: "runtime-tmp"
							emptyDir: sizeLimit: #config.runtimeStorage.sizeLimit
						},
						{
							name: "npm-cache"
							emptyDir: sizeLimit: #config.runtimeStorage.sizeLimit
						},
					],
					[
						if #config.certificate.enabled {
							name: "signing-certificate"
							secret: {
								secretName: #config.certificate.existingSecret
								items: [{
									key:  #config.certificate.fileKey
									path: #config.certificate.fileKey
								}]
							}
						},
					],
					#config.extraVolumes,
				])
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.affinity) > 0 {
					affinity: #config.affinity
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				if len(#config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
			}
		}
	}
}
