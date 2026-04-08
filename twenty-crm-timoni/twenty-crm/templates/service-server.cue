package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServerService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name: "\(#config.metadata.name)-server"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "server"
		}
	}
	spec: corev1.#ServiceSpec & {
		type:     #config.server.service.type
		selector: {
			"app.kubernetes.io/name":      #config.metadata.name
			"app.kubernetes.io/component": "server"
		}
		ports: [
			{
				port:       #config.server.service.port
				targetPort: "http-tcp"
				protocol:   "TCP"
				name:       "http-tcp"
			},
		]
	}
}
