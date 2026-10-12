package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels:    #config.#labels
		if #config.service.annotations != _|_ && len(#config.service.annotations) > 0 {
			annotations: #config.service.annotations
		}
	}
	spec: {
		type: #config.service.type
		if #config.service.ipFamilyPolicy != _|_ {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if #config.service.ipFamilies != _|_ {
			ipFamilies: #config.service.ipFamilies
		}
		selector: #config.#selectorLabels
		ports: [
			{
				name:       "http"
				port:       #config.service.port
				targetPort: "http"
				protocol:   "TCP"
			},
		]
	}
}
