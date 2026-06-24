package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.fullname
		namespace: #config.namespace
		labels:    #config.labels
	}
	spec: {
		type: #config.service.type
		if #config.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if len(#config.service.ipFamilies) > 0 {
			ipFamilies: #config.service.ipFamilies
		}
		ports: [
			{
				name:       "http"
				port:       #config.service.port
				targetPort: "http"
				protocol:   "TCP"
			},
		]
		selector: #config.selectorLabels
	}
}
