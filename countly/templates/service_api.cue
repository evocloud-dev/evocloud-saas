package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceApi: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-api"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-api"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/version":    #config.moduleVersion
			"app.kubernetes.io/managed-by": "timoni"
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.api.service.type
		ports: [
			{
				name:       "http"
				port:       #config.api.service.port
				targetPort: "http"
				protocol:   "TCP"
			},
		]
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-api"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}
