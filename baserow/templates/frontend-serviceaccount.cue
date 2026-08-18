package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccountFrontend: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		if #config.frontend.serviceAccount.name != "" {
			name: #config.frontend.serviceAccount.name
		}
		if #config.frontend.serviceAccount.name == "" {
			name: "\(#config.metadata.name)-frontend"
		}
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.frontend.serviceAccount.annotations != _|_ {
			annotations: #config.frontend.serviceAccount.annotations
		}
	}
}
