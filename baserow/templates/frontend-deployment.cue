package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

#DeploymentFrontend: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-frontend"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		if !#config.frontend.autoscaling.enabled {
			replicas: #config.frontend.replicaCount
		}
		revisionHistoryLimit: #config.frontend.revisionHistoryLimit
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-frontend"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				if #config.frontend.podAnnotations != _|_ {
					annotations: #config.frontend.podAnnotations
				}
				labels: {
					"app.kubernetes.io/name":     "\(#config.metadata.name)-frontend"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: {
				automountServiceAccountToken: false
				if len(#config.frontend.imagePullSecrets) > 0 {
					imagePullSecrets: #config.frontend.imagePullSecrets
				}
				if #config.frontend.serviceAccount.create {
					if #config.frontend.serviceAccount.name != "" {
						serviceAccountName: #config.frontend.serviceAccount.name
					}
					if #config.frontend.serviceAccount.name == "" {
						serviceAccountName: "\(#config.metadata.name)-frontend"
					}
				}
				if !#config.frontend.serviceAccount.create {
					if #config.frontend.serviceAccount.name != "" {
						serviceAccountName: #config.frontend.serviceAccount.name
					}
					if #config.frontend.serviceAccount.name == "" {
						serviceAccountName: "default"
					}
				}
				if #config.frontend.podSecurityContext != _|_ {
					securityContext: #config.frontend.podSecurityContext
				}
				containers: [
					{
						name:            "frontend"
						image:           "\(#config.frontend.image.registry)/\(#config.frontend.image.repository):\(#config.frontend.image.tag)"
						imagePullPolicy: #config.frontend.image.pullPolicy
						args: [
							"nuxt",
						]
						if len(#config.frontend.extraEnv) > 0 {
							env: #config.frontend.extraEnv
						}
						envFrom: [
							{
								configMapRef: name: "\(#config.metadata.name)"
							},
							{
								configMapRef: name: "\(#config.metadata.name)-backend" // Assuming backend is the main shared one
							},
							{
								configMapRef: name: "\(#config.metadata.name)-frontend"
							},
						]
						ports: [
							{
								name:          "http"
								containerPort: #config.frontend.service.port
								protocol:      "TCP"
							},
						]
						if #config.frontend.livenessProbe != _|_ {
							livenessProbe: {
								httpGet: {
									path: "/_health/"
									port: #config.frontend.service.port
								}
								if #config.frontend.livenessProbe.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.frontend.livenessProbe.initialDelaySeconds
								}
								if #config.frontend.livenessProbe.periodSeconds != _|_ {
									periodSeconds: #config.frontend.livenessProbe.periodSeconds
								}
								if #config.frontend.livenessProbe.successThreshold != _|_ {
									successThreshold: #config.frontend.livenessProbe.successThreshold
								}
								if #config.frontend.livenessProbe.timeoutSeconds != _|_ {
									timeoutSeconds: #config.frontend.livenessProbe.timeoutSeconds
								}
							}
						}
						if #config.frontend.readinessProbe != _|_ {
							readinessProbe: {
								httpGet: {
									path: "/_health/"
									port: #config.frontend.service.port
								}
								if #config.frontend.readinessProbe.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.frontend.readinessProbe.initialDelaySeconds
								}
								if #config.frontend.readinessProbe.periodSeconds != _|_ {
									periodSeconds: #config.frontend.readinessProbe.periodSeconds
								}
								if #config.frontend.readinessProbe.successThreshold != _|_ {
									successThreshold: #config.frontend.readinessProbe.successThreshold
								}
								if #config.frontend.readinessProbe.timeoutSeconds != _|_ {
									timeoutSeconds: #config.frontend.readinessProbe.timeoutSeconds
								}
							}
						}
						if #config.frontend.resources != _|_ {
							resources: #config.frontend.resources
						}
						if #config.frontend.securityContext != _|_ {
							securityContext: #config.frontend.securityContext
						}
					},
				]
				if #config.frontend.priorityClassName != "" {
					priorityClassName: #config.frontend.priorityClassName
				}
				if #config.frontend.nodeSelector != _|_ {
					nodeSelector: #config.frontend.nodeSelector
				}
				if #config.frontend.affinity != _|_ {
					affinity: #config.frontend.affinity
				}
				if len(#config.frontend.tolerations) > 0 {
					tolerations: #config.frontend.tolerations
				}
			}
		}
	}
}
