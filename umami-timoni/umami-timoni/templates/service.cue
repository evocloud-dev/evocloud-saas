package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata:   #config.metadata
	if #config.service.annotations != _|_ {
		metadata: annotations: #config.service.annotations
	}
	spec: corev1.#ServiceSpec & {
		type:            #config.service.type
		sessionAffinity: "ClientIP"
		selector:        #config.selector.labels
		ports: [
			{
				port:       #config.service.port
				targetPort: "http"
				protocol:   "TCP"
				name:       "http"
			},
		]
	}
}
