package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#IframelyService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-iframely"
	}
	spec: {
		clusterIP: "None"
		ports: [{
			name:       "iframely-8061"
			port:       8061
			protocol:   "TCP"
			targetPort: 8061
		}]
		selector: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-iframely"
		}
	}
}

#IframelyDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-iframely-wl"
	}
	spec: {
		replicas: #config.services.iframely.replicas
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-iframely"
		}
		template: {
			metadata: {
				namespace: #config.#namespace
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-iframely"
				}
				annotations: {
					timestamp: "placeholder"
				}
			}
			spec: {
				containers: [{
					name:            "\(#config.metadata.name)-iframely"
					image:           #config.services.iframely.image
					imagePullPolicy: "Always"
					stdin:           true
					tty:             true
					resources:       #config.services.iframely.resources
					command: ["node"]
					args: ["server.js"]
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
