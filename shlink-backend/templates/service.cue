package templates

import corev1 "k8s.io/api/core/v1"

#Service: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata:   #config.metadata & {
		name: #config.#serviceName
	}
	spec: corev1.#ServiceSpec & {
		type: #config.service.type
		selector: #config.selector.labels & #config.podLabels
		ports: [{
			port:       #config.service.port
			targetPort: name
			protocol:   "TCP"
			name:       "http"
		}]
	}
}