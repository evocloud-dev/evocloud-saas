package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SummaryService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-summary"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "summary"
		}
		if #config.summary.service.annotations != _|_ {
			annotations: #config.summary.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.summary.service.type
		ports: [{
			name:       "http"
			port:       #config.summary.service.port
			targetPort: #config.summary.service.targetPort
			protocol:   "TCP"
		}]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "summary"
		}
	}
}