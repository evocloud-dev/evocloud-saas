package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config._name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ if len(#config.metadata.annotations) > 0 {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		strategy: type:        appsv1.#RecreateDeploymentStrategyType
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if #config.podLabels != _|_ {
					labels: #config.podLabels
				}
				if #config.podAnnotations != _|_ if len(#config.podAnnotations) > 0 {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: #config._serviceAccountName
				let _automount = [
					if #config.serviceAccount.automountServiceAccountToken != _|_ {
						#config.serviceAccount.automountServiceAccountToken
					},
					false,
				][0]
				automountServiceAccountToken: _automount
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				if #config.podSecurityContext != _|_ if #config.podSecurityContext != {} {
					securityContext: #config.podSecurityContext
				}
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}

				if #config.database.type == "mariadb" {
					initContainers: [
						{
							name:  "wait-for-db"
							image: "docker.io/library/busybox:1.37"
							command: [
								"sh",
								"-c",
								"""
								echo "Waiting for database at \(#config._dbHost):\(#config._dbPort)..."
								until nc -z -w2 \(#config._dbHost) \(#config._dbPort); do
								  echo "Database not ready, retrying in 2s..."
								  sleep 2
								done
								echo "Database is ready."
								""",
							]
						},
					]
				}

				containers: [
					{
						name:            "uptime-kuma"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						ports: [
							{
								name:          "http"
								containerPort: #config.uptimeKuma.port
								protocol:      corev1.#ProtocolTCP
							},
						]
						env: [
							{
								name:  "UPTIME_KUMA_PORT"
								value: "\(#config.uptimeKuma.port)"
							},
							{
								name:  "DATA_DIR"
								value: "/app/data"
							},
							if #config.uptimeKuma.disableFrameSameOrigin {
								name:  "UPTIME_KUMA_DISABLE_FRAME_SAMEORIGIN"
								value: "true"
							},
							if #config.database.type == "mariadb" {
								name:  "UPTIME_KUMA_DB_TYPE"
								value: "mariadb"
							},
							if #config.database.type == "mariadb" {
								name:  "UPTIME_KUMA_DB_HOSTNAME"
								value: #config._dbHost
							},
							if #config.database.type == "mariadb" {
								name:  "UPTIME_KUMA_DB_PORT"
								value: #config._dbPort
							},
							if #config.database.type == "mariadb" {
								name:  "UPTIME_KUMA_DB_NAME"
								value: #config._dbName
							},
							if #config.database.type == "mariadb" {
								name:  "UPTIME_KUMA_DB_USERNAME"
								value: #config._dbUsername
							},
							if #config.database.type == "mariadb" {
								name: "UPTIME_KUMA_DB_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config._dbSecretName
									key:  #config._dbSecretPasswordKey
								}
							},
							for e in #config.uptimeKuma.extraEnv {e},
						]
						if #config.probes.startup.enabled {
							startupProbe: {
								httpGet: {
									path: #config.probes.startup.path
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
								httpGet: {
									path: #config.probes.liveness.path
									port: "http"
								}
								initialDelaySeconds: #config.probes.liveness.initialDelaySeconds
								periodSeconds:       #config.probes.liveness.periodSeconds
								timeoutSeconds:      #config.probes.liveness.timeoutSeconds
								failureThreshold:    #config.probes.liveness.failureThreshold
							}
						}
						if #config.probes.readiness.enabled {
							readinessProbe: {
								httpGet: {
									path: #config.probes.readiness.path
									port: "http"
								}
								initialDelaySeconds: #config.probes.readiness.initialDelaySeconds
								periodSeconds:       #config.probes.readiness.periodSeconds
								timeoutSeconds:      #config.probes.readiness.timeoutSeconds
								failureThreshold:    #config.probes.readiness.failureThreshold
							}
						}
						if #config.resources != {} {
							resources: #config.resources
						}
						if #config.securityContext != _|_ if #config.securityContext != {} {
							securityContext: #config.securityContext
						}
						if #config.lifecycle != {} {
							lifecycle: #config.lifecycle
						}
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/app/data"
							},
							for vm in #config.extraVolumeMounts {vm},
						]
					},
				]

				volumes: [
					{
						name: "data"
						if #config.persistence.enabled {
							persistentVolumeClaim: claimName: #config._dataClaimName
						}
						if !#config.persistence.enabled {
							emptyDir: {}
						}
					},
					for v in #config.extraVolumes {v},
				]

				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				if len(#config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.affinity != _|_ if #config.affinity != {} {
					affinity: #config.affinity
				}
			}
		}
	}
}
