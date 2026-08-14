package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccountWsgi: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		if #config.backend.wsgi.serviceAccount.name != "" {
			name: #config.backend.wsgi.serviceAccount.name
		}
		if #config.backend.wsgi.serviceAccount.name == "" {
			name: "\(#config.metadata.name)-wsgi"
		}
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.backend.wsgi.serviceAccount.annotations != _|_ {
			annotations: #config.backend.wsgi.serviceAccount.annotations
		}
	}
}
