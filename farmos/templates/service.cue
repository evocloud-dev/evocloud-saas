package templates

import (
	"strings"

	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"service.name": "main"
		}
		if #config.service.main.annotations != _|_ {
			annotations: #config.service.main.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type:                     #config.service.main.type
		publishNotReadyAddresses: false
		ports: [
			{
				name:       "main"
				port:       #config.service.main.ports.main.port
				protocol:   strings.ToUpper(#config.service.main.ports.main.protocol)
				targetPort: #config.service.main.ports.main.targetPort
			},
		]
		selector: #config.selector.labels
	}
}
