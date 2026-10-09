package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata:   #config.metadata
	metadata: labels: {
		"service.name": "main"
	}
	if #config.service.main.annotations != _|_ {
		metadata: annotations: #config.service.main.annotations
	}
	spec: corev1.#ServiceSpec & {
		type:                     #config.service.main.type
		publishNotReadyAddresses: *false | bool
		selector: {
			#config.selector.labels
			"pod.name": "main"
		}
		ports: [
			{
				name:       "main"
				port:       #config.service.main.ports.main.port
				targetPort: #config.service.main.ports.main.targetPort
				protocol:   #config.service.main.ports.main.protocol
			},
		]
	}
}
