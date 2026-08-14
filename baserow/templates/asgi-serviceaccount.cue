package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccountAsgi: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		if #config.backend.asgi.serviceAccount.name != "" {
			name: #config.backend.asgi.serviceAccount.name
		}
		if #config.backend.asgi.serviceAccount.name == "" {
			name: "\(#config.metadata.name)-asgi"
		}
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.backend.asgi.serviceAccount.annotations != _|_ {
			annotations: #config.backend.asgi.serviceAccount.annotations
		}
	}
}
