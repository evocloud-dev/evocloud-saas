package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		if #config.serviceAccount.name != "" {
			name: #config.serviceAccount.name
		}
		if #config.serviceAccount.name == "" {
			name: #config.metadata.name
		}
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.serviceAccount.annotations != _|_ {
			annotations: #config.serviceAccount.annotations
		}
	}
}
