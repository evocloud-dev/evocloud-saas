package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels: {
			#config.metadata.labels
			"app.kubernetes.io/component": "discourse"
		}
		if #config.service.annotations != _|_ {
			annotations: #config.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.service.type
		if #config.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if len(#config.service.ipFamilies) > 0 {
			ipFamilies: [
				for ipf in #config.service.ipFamilies {
					corev1.#IPFamily & ipf
				},
			]
		}
		ports: [
			{
				name:       "http"
				port:       #config.service.port
				targetPort: "http"
				protocol:   corev1.#ProtocolTCP
			},
		]
		selector: #config.selector.labels
	}
}
