package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: #config.metadata & {
		labels: {
			"service.name": "main"
		}
	}
	if #config.service.main.annotations != _|_ {
		metadata: annotations: #config.service.main.annotations
	}
	spec: corev1.#ServiceSpec & {
		type:                     #config.service.main.type
		publishNotReadyAddresses: #config.service.main.publishNotReadyAddresses
		selector:                 #config.selector.labels
		ports: [
			if #config.service.main.ports.main.enabled {
				{
					name:       "main"
					port:       #config.service.main.ports.main.port
					protocol:   #config.service.main.ports.main.protocol
					targetPort: #config.service.main.ports.main.targetPort
				}
			},
		]
	}
}
