package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#YProviderService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-y-provider"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "yProvider"
		}
		if #config.yProvider.service.annotations != _|_ {
			annotations: #config.yProvider.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.yProvider.service.type
		ports: [{
			name:       "http"
			port:       #config.yProvider.service.port
			targetPort: #config.yProvider.service.targetPort
			protocol:   "TCP"
		}]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "yProvider"
		}
	}
}
