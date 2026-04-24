package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#PIAPIService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-pi-api"
	}
	spec: {
		type: "ClusterIP"
		if !#config.services.pi.assign_cluster_ip {
		clusterIP: "None"
		}
		ports: [{
			name:       "pi-api-8000"
			port:       8000
			protocol:   "TCP"
			targetPort: 8000
		}]
		selector: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-pi-api"
		}
	}
}

#PIAPIDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-pi-api-wl"
	}
	spec: {
		replicas: #config.services.pi.replicas
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-pi-api"
		}
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-pi-api"
				}
				annotations: {
					timestamp: "placeholder"
				}
			}
			spec: {
				containers: [{
					name:            "\(#config.metadata.name)-pi-api"
					image:           "\(#config.services.pi.image):\(#config.planeVersion)"
					imagePullPolicy: "Always"
					stdin:           true
					tty:             true
					command: [
						"/bin/bash",
						"-c",
						"set -e\nexec ./bin/entrypoint-api.sh\n",
					]
					resources: #config.services.api.resources 
					envFrom: [
						{configMapRef: name: "\(#config.metadata.name)-pi-api-vars"},
						{secretRef: name:    "\(#config.metadata.name)-pi-api-secrets"},
						{secretRef: name:    "\(#config.metadata.name)-doc-store-secrets"},
						{secretRef: name:    "\(#config.metadata.name)-opensearch-secrets"},
					]
					readinessProbe: {
						failureThreshold: 30
						httpGet: {
							path:   "/pi/"
							port:   8000
							scheme: "HTTP"
						}
						periodSeconds:    10
						successThreshold: 1
						timeoutSeconds:   1
					}
				}]
				serviceAccount:     "\(#config.metadata.name)-srv-account"
				serviceAccountName: "\(#config.metadata.name)-srv-account"
			}
		}
	}
}
