package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#AdminService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-admin"
	}
	spec: {
		type: "ClusterIP"
		if !#config.services.admin.assign_cluster_ip {
			clusterIP: "None"
		}
		ports: [{
			name:       "admin-3000"
			port:       3000
			protocol:   "TCP"
			targetPort: 3000
		}]
		selector: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-admin"
		}
	}
}

#AdminDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-admin-wl"
	}
	spec: {
		replicas: #config.services.admin.replicas
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-admin"
		}
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-admin"
				}
				annotations: {
					timestamp: "placeholder"
				}
			}
			spec: {
				containers: [{
					name:            "\(#config.metadata.name)-admin"
					image:           "\(#config.services.admin.image):\(#config.planeVersion)"
					imagePullPolicy: "Always"
					stdin:           true
					tty:             true
					resources:       #config.services.admin.resources
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
