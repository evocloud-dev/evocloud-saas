package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#BitwardenCliDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "bitwarden-cli-\(#config.metadata.namespace)"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/instance": "bitwarden-cli"
			"app.kubernetes.io/name":     "bitwarden-cli"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		strategy: type: "Recreate"
		selector: matchLabels: {
			"app.kubernetes.io/name":     "bitwarden-cli"
			"app.kubernetes.io/instance": "bitwarden-cli"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     "bitwarden-cli"
				"app.kubernetes.io/instance": "bitwarden-cli"
			}
			spec: corev1.#PodSpec & {
				containers: [{
					name:            "bitwarden-cli"
					image:           "lasuite/vaultwarden-api:0.1"
					imagePullPolicy: "Always"
					env: [{
						name: "BW_HOST"
						valueFrom: secretKeyRef: {
							name: "bitwarden-cli-\(#config.metadata.namespace)"
							key:  "BW_HOST"
						}
					}, {
						name: "BW_USER"
						valueFrom: secretKeyRef: {
							name: "bitwarden-cli-\(#config.metadata.namespace)"
							key:  "BW_USERNAME"
						}
					}, {
						name: "BW_PASSWORD"
						valueFrom: secretKeyRef: {
							name: "bitwarden-cli-\(#config.metadata.namespace)"
							key:  "BW_PASSWORD"
						}
					}]
					ports: [{
						name:          "http"
						containerPort: 8087
						protocol:      "TCP"
					}]
					livenessProbe: {
						exec: command: [
							"wget",
							"-q",
							"http://127.0.0.1:8087/sync?force=true",
							"--post-data=''",
						]
						initialDelaySeconds: 20
						failureThreshold:    3
						timeoutSeconds:      10
						periodSeconds:       120
					}
					readinessProbe: {
						tcpSocket: port: 8087
						initialDelaySeconds: 20
						failureThreshold:    3
						timeoutSeconds:      1
						periodSeconds:       10
					}
					startupProbe: {
						tcpSocket: port: 8087
						initialDelaySeconds: 10
						failureThreshold:    30
						timeoutSeconds:      1
						periodSeconds:       5
					}
				}]
			}
		}
	}
}

#BitwardenCliService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "bitwarden-cli-\(#config.metadata.namespace)"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/instance": "bitwarden-cli"
			"app.kubernetes.io/name":     "bitwarden-cli"
		}
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [{
			port:       8087
			targetPort: 8087
			protocol:   "TCP"
			name:       "http"
		}]
		selector: {
			"app.kubernetes.io/name":     "bitwarden-cli"
			"app.kubernetes.io/instance": "bitwarden-cli"
		}
	}
}

#ClusterSecretStore: {
	#config: #Config
	#name:   string
	#url:    string
	#jsonPath: string

	apiVersion: "external-secrets.io/v1beta1"
	kind:       "ClusterSecretStore"
	metadata: {
		name:      #name
		namespace: #config.metadata.namespace
	}
	spec: {
		provider: webhook: {
			url: #url
			if #jsonPath != "" {
				headers: "Content-Type": "application/json"
				result: jsonPath:        #jsonPath
			}
		}
	}
}

#ExternalSecret: {
	#config: #Config

	apiVersion: "external-secrets.io/v1beta1"
	kind:       "ExternalSecret"
	metadata: {
		name:      "backend"
		namespace: #config.metadata.namespace
	}
	spec: {
		refreshInterval: "1m"
		target: {
			name:           "backend"
			deletionPolicy: "Delete"
			template: {
				type: "Opaque"
				data: [string]: string
			}
		}
		data: [...{
			secretKey: string
			sourceRef: storeRef: {
				name: string
				kind: "ClusterSecretStore"
			}
			remoteRef: {
				key:      string
				property: string
			}
		}]
	}
}
