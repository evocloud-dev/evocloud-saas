package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.service.annotations) > 0 {
			annotations: #config.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.service.type
		ports: [{
			name:       "http"
			port:       #config.service.port
			targetPort: "http"
			protocol:   "TCP"
		}]
		selector: #config.selector.labels
		if #config.service.ipFamilyPolicy != null {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if len(#config.service.ipFamilies) > 0 {
			ipFamilies: #config.service.ipFamilies
		}
	}
}
