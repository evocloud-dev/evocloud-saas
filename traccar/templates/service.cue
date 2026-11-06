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
			"service.name":              "main"
		}
		if #config.service.annotations != _|_ {
			annotations: #config.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type:                     corev1.#ServiceTypeClusterIP
		publishNotReadyAddresses: false
		selector:                 #config.selector.labels
		ports: [
			{
				name:       #config.service.portName
				port:       #config.service.port
				protocol:   corev1.#ProtocolTCP
				targetPort: #config.service.targetPort
			},
		]
	}
}
