package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DocSpecService: corev1.#Service & {
	#config: #Config
	let docSpec = #config.docSpec

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-docspec"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "docspec"
		}
	}
	spec: corev1.#ServiceSpec & {
		type: docSpec.service.type
		ports: [
			{
				port:       docSpec.service.port
				targetPort: docSpec.service.targetPort
				protocol:   "TCP"
				name:       "http"
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "docspec"
		}
	}
}
