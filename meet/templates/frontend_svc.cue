package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#FrontendService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-frontend"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "frontend"
		}
		if #config.frontend.service.annotations != _|_ {
			annotations: #config.frontend.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.frontend.service.type
		ports: [{
			name:       "http"
			port:       #config.frontend.service.port
			targetPort: #config.frontend.service.targetPort
			protocol:   "TCP"
		}]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "frontend"
		}
	}
}