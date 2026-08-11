package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#DeploymentFrontend: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-frontend"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-frontend"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/version":    #config.moduleVersion
			"app.kubernetes.io/managed-by": "timoni"
		}
	}

	_serviceAccountName: string
	if #config.frontend.serviceAccount.name != "" {
		_serviceAccountName: #config.frontend.serviceAccount.name
	}
	if #config.frontend.serviceAccount.name == "" {
		_serviceAccountName: "\(#config.metadata.name)-frontend"
	}

	_mongodbUrl: string
	if #config.mongodb.enabled {
		_mongodbUrl: "mongodb://\(#config.metadata.name)-mongodb:27017/\(#config.mongodb.auth.database)"
	}
	if !#config.mongodb.enabled {
		_mongodbUrl: "mongodb://\(#config.externalMongodb.hostname):\(#config.externalMongodb.port)/\(#config.externalMongodb.auth.database)"
	}

	spec: appsv1.#DeploymentSpec & {
		replicas: #config.frontend.replicaCount
		revisionHistoryLimit: #config.frontend.revisionHistoryLimit
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-frontend"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     "\(#config.metadata.name)-frontend"
					"app.kubernetes.io/instance": #config.metadata.name
					if #config.frontend.selectorLabels != _|_ {
						for k, v in #config.frontend.selectorLabels {
							"\(k)": v
						}
					}
				}
				if #config.frontend.podAnnotations != _|_ {
					annotations: #config.frontend.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: _serviceAccountName
				
				if #config.frontend.imagePullSecrets != _|_ {
					imagePullSecrets: #config.frontend.imagePullSecrets
				}
				if #config.frontend.podSecurityContext != _|_ {
					securityContext: #config.frontend.podSecurityContext
				}
				if #config.frontend.priorityClassName != "" {
					priorityClassName: #config.frontend.priorityClassName
				}

				//  1. Declares the ephemeral storage volume boundary
				volumes: [
					{
						name: "countly-app-volume"
						emptyDir: {}
					}
				]

				// 2. Injecting initContainer to shift binary permissions before startup
				initContainers: [
					{
						name:  "prepare-countly-permissions"
						image: "\(#config.frontend.image.registry)/\(#config.frontend.image.repository):\(#config.frontend.image.tag)"
						// Extracts image files over to the shared mount point and recursively adjusts user IDs
						command: ["sh", "-c", "cp -a /opt/countly/. /mnt/countly && chown -R 65510:65510 /mnt/countly"]
						securityContext: {
							runAsUser: 0 // Briefly requires root privileges exclusively to alter the mount ownership boundaries
						}
						volumeMounts: [
							{
								name:      "countly-app-volume"
								mountPath: "/mnt/countly"
							}
						]
					}
				]

				containers: [
					{
						name:            "\(#config.metadata.name)-frontend"
						image:           "\(#config.frontend.image.registry)/\(#config.frontend.image.repository):\(#config.frontend.image.tag)"
						imagePullPolicy: #config.frontend.image.pullPolicy
						
						let envMap = {
							"COUNTLY_PLUGINS": #config.config.plugins
							"COUNTLY_CONFIG_API_FILESTORAGE": #config.config.api.filestorage
							"COUNTLY_CONFIG_API_API_WORKERS": #config.config.api.workerCount
							"COUNTLY_CONFIG__MONGODB": _mongodbUrl
							"NODE_OPTIONS": #config.config.nodeOptions
							if #config.hostname != "" {
								"COUNTLY_CONFIG_HOSTNAME": #config.hostname
							}
						}

						env: [
							for k, v in envMap {
								name: k
								value: v
							},
							for x in #config.extraEnv { x },
							for x in #config.frontend.extraEnv { x }
						]

						ports: [
							{
								name:          "http"
								containerPort: 6001
								protocol:      "TCP"
							},
						]

						// 3. Mounts the updated directory context directly onto the application workspace
						volumeMounts: [
							{
								name:      "countly-app-volume"
								mountPath: "/opt/countly/"
							}
						]

						livenessProbe: corev1.#Probe & {
							httpGet: {
								path: "/ping"
								port: 6001
							}
							failureThreshold:    #config.frontend.livenessProbe.failureThreshold
							initialDelaySeconds: #config.frontend.livenessProbe.initialDelaySeconds
							periodSeconds:       #config.frontend.livenessProbe.periodSeconds
							successThreshold:    #config.frontend.livenessProbe.successThreshold
							timeoutSeconds:      #config.frontend.livenessProbe.timeoutSeconds
						}

						readinessProbe: corev1.#Probe & {
							httpGet: {
								path: "/ping"
								port: 6001
							}
							failureThreshold:    #config.frontend.readinessProbe.failureThreshold
							initialDelaySeconds: #config.frontend.readinessProbe.initialDelaySeconds
							periodSeconds:       #config.frontend.readinessProbe.periodSeconds
							successThreshold:    #config.frontend.readinessProbe.successThreshold
							timeoutSeconds:      #config.frontend.readinessProbe.timeoutSeconds
						}

						if #config.frontend.resources != _|_ {
							resources: #config.frontend.resources
						}
						if #config.frontend.securityContext != _|_ {
							securityContext: #config.frontend.securityContext
						}
					},
				]

				if #config.frontend.nodeSelector != _|_ {
					nodeSelector: #config.frontend.nodeSelector
				}
				if #config.frontend.affinity != _|_ {
					affinity: #config.frontend.affinity
				}
				if #config.frontend.tolerations != _|_ {
					tolerations: #config.frontend.tolerations
				}
			}
		}
	}
}
