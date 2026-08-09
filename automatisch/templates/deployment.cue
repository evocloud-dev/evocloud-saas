package templates

import (
	"list"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicas
		strategy: type: "Recreate"
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels & #config.podLabels
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.serviceAccount.name != "" || #config.serviceAccount.create {
					serviceAccountName: [
						if #config.serviceAccount.name != "" {
							#config.serviceAccount.name
						},
						if #config.serviceAccount.name == "" {
							#config.fullname
						}
					][0]
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				initContainers: [
					{
						name:  "wait-for-db"
						image: "docker.io/library/busybox:1.37"
						command: [
							"sh",
							"-c",
							"echo \"Waiting for database at \(#config.dbHost):\(#config.dbPort)...\"\nuntil nc -z -w2 \(#config.dbHost) \(#config.dbPort); do\n  echo \"Database not ready, retrying in 2s...\"\n  sleep 2\ndone\necho \"Database is ready.\"\n",
						]
					},
				]
				containers: [
					{
						name:            "automatisch"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						ports: [
							{
								name:          "http"
								containerPort: 3000
								protocol:      "TCP"
							},
						]
						env: list.Concat([[
							{
								name:  "APP_ENV"
								value: #config.automatisch.appEnv
							},
							{
								name:  "WEB_APP_URL"
								value: #config.automatisch.webAppUrl
							},
							{
								name:  "POSTGRES_HOST"
								value: #config.dbHost
							},
							{
								name:  "POSTGRES_PORT"
								value: #config.dbPort
							},
							{
								name:  "POSTGRES_DATABASE"
								value: #config.dbName
							},
							{
								name:  "POSTGRES_USERNAME"
								value: #config.dbUsername
							},
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.dbSecretName
									key:  #config.dbSecretPasswordKey
								}
							},
							{
								name:  "REDIS_HOST"
								value: #config.redisHost
							},
							{
								name:  "REDIS_PORT"
								value: #config.redisPort
							},
							{
								name: "ENCRYPTION_KEY"
								valueFrom: secretKeyRef: {
									name: #config.appSecretName
									key:  "encryption-key"
								}
							},
							{
								name: "APP_SECRET_KEY"
								valueFrom: secretKeyRef: {
									name: #config.appSecretName
									key:  "app-secret-key"
								}
							},
							{
								name: "WEBHOOK_SECRET_KEY"
								valueFrom: secretKeyRef: {
									name: #config.appSecretName
									key:  "webhook-secret-key"
								}
							},
						], #config.automatisch.extraEnv])
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
						if #config.extraVolumeMounts != _|_ {
							volumeMounts: #config.extraVolumeMounts
						}
					},
				]
				if #config.extraVolumes != _|_ {
					volumes: #config.extraVolumes
				}
				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
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
