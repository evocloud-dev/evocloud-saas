package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#MainService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"service.name": "main"
		}
	}
	spec: corev1.#ServiceSpec & {
		type:                     corev1.#ServiceTypeClusterIP
		publishNotReadyAddresses: false
		ports: [
			{
				name:       "main"
				port:       #config.service.main.ports.main.port
				protocol:   "TCP"
				targetPort: #config.service.main.ports.main.targetPort
			},
		]
		selector: {
			"pod.name":                  "main"
			"app.kubernetes.io/name":     #config.metadata.name
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}
