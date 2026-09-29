package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config._name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.service.annotations != _|_ if len(#config.service.annotations) > 0 {
			annotations: #config.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type:     #config.service.type
		selector: #config.selector.labels
		ports: [
			{
				name:       "http"
				port:       #config.service.port
				targetPort: "http"
				protocol:   corev1.#ProtocolTCP
			},
		]
		if #config.service.ipFamilyPolicy != _|_ {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if #config.service.ipFamilies != _|_ {
			ipFamilies: #config.service.ipFamilies
		}
	}
}
