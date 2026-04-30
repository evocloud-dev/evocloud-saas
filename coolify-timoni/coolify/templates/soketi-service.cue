package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SoketiService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-soketi-svc"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "soketi"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.soketi.service.type
		ports: [
			{
				name:       "app"
				port:       #config.soketi.service.appPort
				targetPort: "soketi-app"
				protocol:   "TCP"
			},
			{
				name:       "metrics"
				port:       #config.soketi.service.metricsPort
				targetPort: "soketi-metrics"
				protocol:   "TCP"
			},
		]
		selector: {
			"app.kubernetes.io/name":      #config.metadata.name
			"app.kubernetes.io/component": "soketi"
		}
	}
}
