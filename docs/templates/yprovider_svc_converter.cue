package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#YProviderConverterService: corev1.#Service & {
	#config: #Config
	let converter = #config.yProvider.converter

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-y-provider-converter"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "yProvider-converter"
		}
		if converter.service.annotations != _|_ {
			annotations: converter.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: converter.service.type
		ports: [
			{
				port:       converter.service.port
				targetPort: converter.service.targetPort
				protocol:   "TCP"
				name:       "http"
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "yProvider-converter"
		}
	}
}
