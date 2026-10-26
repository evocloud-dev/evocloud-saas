package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ClientServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name: [
			if #config.client.serviceAccount.name != "" {#config.client.serviceAccount.name},
			"\(#config.metadata.name)-client",
		][0]
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
}
