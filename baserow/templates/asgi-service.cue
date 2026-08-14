package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAsgi: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-asgi"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		type:     corev1.#ServiceType & #config.backend.asgi.service.type
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-asgi"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		ports: [
			{
				name:       "http"
				port:       #config.backend.asgi.service.port
				targetPort: "http"
				protocol:   "TCP"
			},
		]
	}
}
