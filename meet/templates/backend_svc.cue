package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#BackendService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-backend"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "backend"
		}
		if #config.backend.service.annotations != _|_ {
			annotations: #config.backend.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.backend.service.type
		ports: [{
			name:       "http"
			port:       #config.backend.service.port
			targetPort: #config.backend.service.targetPort
			protocol:   "TCP"
		}]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "backend"
		}
	}
}