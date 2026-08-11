package templates

import (
	"struct"

	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if struct.MinFields(#config.service.annotations, 1) {
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
				protocol:   "TCP"
			},
		]
		if #config.service.ipFamilyPolicy != _|_ && #config.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if #config.service.ipFamilies != _|_ && len(#config.service.ipFamilies) > 0 {
			ipFamilies: #config.service.ipFamilies
		}
	}
}
