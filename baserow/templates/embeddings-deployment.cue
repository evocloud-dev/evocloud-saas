package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

#DeploymentEmbeddings: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-embeddings"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		if !#config.embeddings.autoscaling.enabled {
			replicas: #config.embeddings.replicaCount
		}
		revisionHistoryLimit: #config.embeddings.revisionHistoryLimit
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-embeddings"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				if #config.embeddings.podAnnotations != _|_ {
					annotations: #config.embeddings.podAnnotations
				}
				labels: {
					"app.kubernetes.io/name":     "\(#config.metadata.name)-embeddings"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: {
				automountServiceAccountToken: false
				if len(#config.embeddings.imagePullSecrets) > 0 {
					imagePullSecrets: #config.embeddings.imagePullSecrets
				}
				if #config.embeddings.serviceAccount.create {
					if #config.embeddings.serviceAccount.name != "" {
						serviceAccountName: #config.embeddings.serviceAccount.name
					}
					if #config.embeddings.serviceAccount.name == "" {
						serviceAccountName: "\(#config.metadata.name)-embeddings"
					}
				}
				if !#config.embeddings.serviceAccount.create {
					if #config.embeddings.serviceAccount.name != "" {
						serviceAccountName: #config.embeddings.serviceAccount.name
					}
					if #config.embeddings.serviceAccount.name == "" {
						serviceAccountName: "default"
					}
				}
				if #config.embeddings.podSecurityContext != _|_ {
					securityContext: #config.embeddings.podSecurityContext
				}
				containers: [
					{
						name:            "embeddings"
						image:           "\(#config.embeddings.image.registry)/\(#config.embeddings.image.repository):\(#config.embeddings.image.tag)"
						imagePullPolicy: #config.embeddings.image.pullPolicy
						ports: [
							{
								name:          "http"
								containerPort: #config.embeddings.service.targetPort
								protocol:      "TCP"
							},
						]
						if #config.embeddings.livenessProbe != _|_ {
							livenessProbe: {
								httpGet: {
									path: "/health"
									port: #config.embeddings.service.targetPort
								}
								if #config.embeddings.livenessProbe.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.embeddings.livenessProbe.initialDelaySeconds
								}
								if #config.embeddings.livenessProbe.timeoutSeconds != _|_ {
									timeoutSeconds: #config.embeddings.livenessProbe.timeoutSeconds
								}
								if #config.embeddings.livenessProbe.periodSeconds != _|_ {
									periodSeconds: #config.embeddings.livenessProbe.periodSeconds
								}
								if #config.embeddings.livenessProbe.failureThreshold != _|_ {
									failureThreshold: #config.embeddings.livenessProbe.failureThreshold
								}
								if #config.embeddings.livenessProbe.successThreshold != _|_ {
									successThreshold: #config.embeddings.livenessProbe.successThreshold
								}
							}
						}
						if #config.embeddings.readinessProbe != _|_ {
							readinessProbe: {
								httpGet: {
									path: "/health"
									port: #config.embeddings.service.targetPort
								}
								if #config.embeddings.readinessProbe.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.embeddings.readinessProbe.initialDelaySeconds
								}
								if #config.embeddings.readinessProbe.timeoutSeconds != _|_ {
									timeoutSeconds: #config.embeddings.readinessProbe.timeoutSeconds
								}
								if #config.embeddings.readinessProbe.periodSeconds != _|_ {
									periodSeconds: #config.embeddings.readinessProbe.periodSeconds
								}
								if #config.embeddings.readinessProbe.failureThreshold != _|_ {
									failureThreshold: #config.embeddings.readinessProbe.failureThreshold
								}
								if #config.embeddings.readinessProbe.successThreshold != _|_ {
									successThreshold: #config.embeddings.readinessProbe.successThreshold
								}
							}
						}
						if #config.embeddings.resources != _|_ {
							resources: #config.embeddings.resources
						}
						if #config.embeddings.securityContext != _|_ {
							securityContext: #config.embeddings.securityContext
						}
					},
				]
				if #config.embeddings.priorityClassName != "" {
					priorityClassName: #config.embeddings.priorityClassName
				}
				if #config.embeddings.nodeSelector != _|_ {
					nodeSelector: #config.embeddings.nodeSelector
				}
				if #config.embeddings.affinity != _|_ {
					affinity: #config.embeddings.affinity
				}
				if len(#config.embeddings.tolerations) > 0 {
					tolerations: #config.embeddings.tolerations
				}
			}
		}
	}
}
