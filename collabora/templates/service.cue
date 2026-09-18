package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.service.annotations != _|_ {
			annotations: #config.service.annotations
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type:                     #config.service.type
		publishNotReadyAddresses: false
		selector:                 #config.selector.labels
		ports: [
			{
				name:       "http"
				port:       #config.service.port
				protocol:   "TCP"
				targetPort: "http"
			},
		]
	}
}
