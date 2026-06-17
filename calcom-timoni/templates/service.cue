package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata:   #config.metadata
	spec: corev1.#ServiceSpec & {
		type: #config.service.main.type
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "calcom"
		}
		ports: [
			{
				port:       #config.service.main.ports.http.port
				protocol:   "TCP"
				name:       "http"
				targetPort: name
			},
		]
	}
}