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
		labels:    #config.metadata.labels
		annotations: {
			if #config.metadata.annotations != _|_ {
				for k, v in #config.metadata.annotations {
					(k): v
				}
			}
			if #config.service.annotations != _|_ {
				for k, v in #config.service.annotations {
					(k): v
				}
			}
		}
	}
	spec: corev1.#ServiceSpec & {
		type:     #config.service.type
		selector: #config.selector.labels
		if #config.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if len(#config.service.ipFamilies) > 0 {
			ipFamilies: [for f in #config.service.ipFamilies {corev1.#IPFamily & f}]
		}
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
