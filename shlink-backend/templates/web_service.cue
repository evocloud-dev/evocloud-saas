package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#WebService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-web"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		ports: [{
			name:       "http"
			port:       #config.web.service.port
			protocol:   "TCP"
			targetPort: "http"
		}]
		selector: {
			"app.kubernetes.io/name":      "\(#config.metadata.name)-web"
			"app.kubernetes.io/instance":  #config.metadata.name
		}
		type: #config.web.service.type
	}
}
