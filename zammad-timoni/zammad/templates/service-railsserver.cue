package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceRailsserver: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-railsserver"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		ports: [
			{
				port:       3000
				targetPort: 3000
				protocol:   "TCP"
				name:       "http"
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "zammad-railsserver"
		}
	}
}
