package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	_affinity: timoniv1.#Affinity & {
		if #config.affinity != _|_ {
			#Values: #config.affinity
		}
		#MatchLabels: #config.selector.labels
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicas
		strategy: type: appsv1.#RecreateDeploymentStrategyType
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if #config.podLabels != _|_ {
					labels: #config.podLabels
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.serviceAccount.create {
					if #config.serviceAccount.name != "" {
						serviceAccountName: #config.serviceAccount.name
					}
					if #config.serviceAccount.name == "" {
						serviceAccountName: #config.metadata.name
					}
				}
				if !#config.serviceAccount.create && #config.serviceAccount.name != "" {
					serviceAccountName: #config.serviceAccount.name
				}
				if #config.serviceAccount.automountServiceAccountToken != _|_ {
					automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds

				if #config.postgresql.enabled && !#config.externalDatabase.enabled {
					initContainers: [
						{
							name:  "wait-for-postgresql"
							image: "docker.io/library/busybox:1.37"
							command: ["sh", "-c", "until nc -z \(#config.metadata.name)-postgresql 5432; do echo waiting for postgresql; sleep 2; done"]
						},
					]
				}

				containers: [
					{
						name:            "middleware"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						ports: [
							{
								name:          "http"
								containerPort: #config.middleware.frontendPort
								protocol:      "TCP"
							},
							{
								name:          "analytics"
								containerPort: #config.middleware.analyticsPort
								protocol:      "TCP"
							},
							{
								name:          "sync"
								containerPort: #config.middleware.syncPort
								protocol:      "TCP"
							},
						]
						env: [
							{
								name:  "ENVIRONMENT"
								value: #config.middleware.environment
							},
							{
								name:  "POSTGRES_DB_ENABLED"
								value: #config.middleware.internalDbEnabled
							},
							{
								name:  "REDIS_ENABLED"
								value: #config.middleware.internalRedisEnabled
							},
							if !#config.externalDatabase.enabled {
								name: "DB_PASS"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-postgresql-auth"
									key:  "user-password"
								}
							},
							if #config.externalDatabase.enabled && #config.externalDatabase.existingSecret != "" {
								name: "DB_PASS"
								valueFrom: secretKeyRef: {
									name: #config.externalDatabase.existingSecret
									key:  #config.externalDatabase.existingSecretPasswordKey
								}
							},
							if #config.externalDatabase.enabled && #config.externalDatabase.existingSecret == "" {
								name:  "DB_PASS"
								value: #config.externalDatabase.password
							},
							{
								name: "DB_HOST"
								if #config.externalDatabase.enabled {
									value: #config.externalDatabase.host
								}
								if !#config.externalDatabase.enabled {
									value: "\(#config.metadata.name)-postgresql"
								}
							},
							{
								name: "DB_PORT"
								if #config.externalDatabase.enabled {
									value: "\(#config.externalDatabase.port)"
								}
								if !#config.externalDatabase.enabled {
									value: "5432"
								}
							},
							{
								name: "DB_NAME"
								if #config.externalDatabase.enabled {
									value: #config.externalDatabase.name
								}
								if !#config.externalDatabase.enabled {
									value: #config.postgresql.auth.database
								}
							},
							{
								name: "DB_USER"
								if #config.externalDatabase.enabled {
									value: #config.externalDatabase.user
								}
								if !#config.externalDatabase.enabled {
									value: #config.postgresql.auth.username
								}
							},
							{
								name: "REDIS_HOST"
								if #config.externalRedis.enabled {
									value: #config.externalRedis.host
								}
								if !#config.externalRedis.enabled {
									value: "\(#config.metadata.name)-redis"
								}
							},
							{
								name: "REDIS_PORT"
								if #config.externalRedis.enabled {
									value: "\(#config.externalRedis.port)"
								}
								if !#config.externalRedis.enabled {
									value: "6379"
								}
							},
							{
								name:  "TZ"
								value: #config.middleware.timezone
							},
							if #config.middleware.extraEnv != _|_ for env in #config.middleware.extraEnv {
								env
							},
						]
						if #config.probes.startup.enabled {
							startupProbe: {
								tcpSocket: port: "http"
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
								tcpSocket: port: "http"
								initialDelaySeconds: #config.probes.readiness.initialDelaySeconds
								periodSeconds:       #config.probes.readiness.periodSeconds
								timeoutSeconds:      #config.probes.readiness.timeoutSeconds
								failureThreshold:    #config.probes.readiness.failureThreshold
							}
						}
						if #config.resources != _|_ {
							resources: #config.resources
						}
						if #config.securityContext != _|_ {
							securityContext: #config.securityContext
						}
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/app/keys"
							},
							if #config.extraVolumeMounts != _|_ for vm in #config.extraVolumeMounts {
								vm
							},
						]
					},
				]
				volumes: [
					{
						name: "data"
						if #config.persistence.enabled {
							persistentVolumeClaim: claimName: {
								if #config.persistence.existingClaim != "" {
									#config.persistence.existingClaim
								}
								if #config.persistence.existingClaim == "" {
									"\(#config.metadata.name)-data"
								}
							}
						}
						if !#config.persistence.enabled {
							emptyDir: {}
						}
					},
					if #config.extraVolumes != _|_ for v in #config.extraVolumes {
						v
					},
				]
				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}
				if #config.affinity != _|_ && _affinity.#Enabled {
					affinity: _affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
			}
		}
	}
}
