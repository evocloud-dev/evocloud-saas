package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	_serviceAccountName: string
	if #config.serviceAccount.create {
		if #config.serviceAccount.name != "" {
			_serviceAccountName: #config.serviceAccount.name
		}
		if #config.serviceAccount.name == "" {
			_serviceAccountName: #config.metadata.name
		}
	}
	if !#config.serviceAccount.create {
		if #config.serviceAccount.name != "" {
			_serviceAccountName: #config.serviceAccount.name
		}
		if #config.serviceAccount.name == "" {
			_serviceAccountName: "default"
		}
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		if !#config.autoscaling.enabled {
			replicas: #config.replicaCount
		}
		strategy: {
			type: "RollingUpdate"
			rollingUpdate: {
				maxSurge:       1
				maxUnavailable: 0
			}
		}
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels & #config.podLabels
				if len(#config.podAnnotations) > 0 {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            _serviceAccountName
				automountServiceAccountToken:  #config.serviceAccount.automountServiceAccountToken
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				securityContext: #config.podSecurityContext
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				containers: [
					{
						name:            "bentopdf"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						securityContext: #config.securityContext
						command: ["nginx"]
						args: ["-g", "daemon off;"]
						ports: [
							{
								name:          "http"
								containerPort: #config.server.port
								protocol:      "TCP"
							},
						]
						resources: #config.resources
						if #config.probes.startup.enabled {
							startupProbe: {
								httpGet: {
									path: #config.probes.startup.path
									port: "http"
								}
								periodSeconds:    #config.probes.startup.periodSeconds
								timeoutSeconds:   #config.probes.startup.timeoutSeconds
								failureThreshold: #config.probes.startup.failureThreshold
							}
						}
						if #config.probes.liveness.enabled {
							livenessProbe: {
								httpGet: {
									path: #config.probes.liveness.path
									port: "http"
								}
								periodSeconds:    #config.probes.liveness.periodSeconds
								timeoutSeconds:   #config.probes.liveness.timeoutSeconds
								failureThreshold: #config.probes.liveness.failureThreshold
							}
						}
						if #config.probes.readiness.enabled {
							readinessProbe: {
								httpGet: {
									path: #config.probes.readiness.path
									port: "http"
								}
								periodSeconds:    #config.probes.readiness.periodSeconds
								timeoutSeconds:   #config.probes.readiness.timeoutSeconds
								failureThreshold: #config.probes.readiness.failureThreshold
							}
						}
						volumeMounts: [
							{
								name:      "config"
								mountPath: "/etc/nginx/nginx.conf"
								subPath:   "nginx.conf"
								readOnly:  true
							},
							{
								name:      "config"
								mountPath: "/usr/share/nginx/html/config.json"
								subPath:   "config.json"
								readOnly:  true
							},
							{
								name:      "nginx-tmp"
								mountPath: "/etc/nginx/tmp"
							},
							{
								name:      "tmp"
								mountPath: "/tmp"
							},
						]
					},
					if #config.metrics.enabled {
						{
							name:            "nginx-exporter"
							image:           #config.metrics.image.reference
							imagePullPolicy: #config.metrics.image.pullPolicy
							args: [
								"--nginx.scrape-uri=http://127.0.0.1:8081/stub_status",
								"--web.listen-address=:\(#config.metrics.port)",
							]
							securityContext: #config.securityContext
							ports: [
								{
									name:          "metrics"
									containerPort: #config.metrics.port
									protocol:      "TCP"
								},
							]
							readinessProbe: {
								httpGet: {
									path: "/metrics"
									port: "metrics"
								}
							}
							livenessProbe: {
								httpGet: {
									path: "/metrics"
									port: "metrics"
								}
							}
							resources: #config.metrics.resources
						}
					},
				]
				volumes: [
					{
						name: "config"
						configMap: name: #config.metadata.name
					},
					{
						name: "nginx-tmp"
						emptyDir: sizeLimit: "64Mi"
					},
					{
						name: "tmp"
						emptyDir: sizeLimit: "32Mi"
					},
				]
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				if len(#config.affinity) > 0 {
					affinity: #config.affinity
				}
				if len(#config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
			}
		}
	}
}
