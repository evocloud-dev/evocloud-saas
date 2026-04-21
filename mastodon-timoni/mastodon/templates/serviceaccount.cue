package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		namespace: #config.#namespace
		name: {
			if #config.serviceAccount.name != "" {
				#config.serviceAccount.name
			}
			if #config.serviceAccount.name == "" {
				#config.metadata.name
			}
		}
		labels: #config.metadata.labels
		if #config.serviceAccount.annotations != _|_ {
			annotations: #config.serviceAccount.annotations
		}
	}
}
