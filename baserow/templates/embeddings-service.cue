package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceEmbeddings: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-embeddings"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		type:     corev1.#ServiceType & #config.embeddings.service.type
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-embeddings"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		ports: [
			{
				name:       "http"
				port:       #config.embeddings.service.port
				targetPort: "http"
				protocol:   "TCP"
			},
		]
	}
}
