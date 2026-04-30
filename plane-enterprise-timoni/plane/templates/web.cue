package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#WebService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-web"
	}
	spec: {
		type: "ClusterIP"
		if !#config.services.web.assign_cluster_ip {
			clusterIP: "None"
		}
		ports: [{
			name:       "web-3000"
			port:       3000
			protocol:   "TCP"
			targetPort: 3000
		}]
		selector: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-web"
		}
	}
}

#WebDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-web-wl"
	}
	spec: {
		replicas: #config.services.web.replicas
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-web"
		}
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-web"
				}
				annotations: {
					timestamp: "placeholder"
				}
			}
			spec: {
				containers: [{
					name:            "\(#config.metadata.name)-web"
					image:           "\(#config.services.web.image):\(#config.planeVersion)"
					imagePullPolicy: "Always"
					stdin:           true
					tty:             true
					resources:       #config.services.web.resources
					if #config.extraEnv != [] {
						env: #config.extraEnv
					}
				}]
				serviceAccount:     "\(#config.metadata.name)-srv-account"
				serviceAccountName: "\(#config.metadata.name)-srv-account"
			}
		}
	}
}
