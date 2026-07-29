package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServerServiceAccount: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name: *"\((#config.metadata.name))-server" | string
		if #config.server.serviceAccount.name != "" {
			name: #config.server.serviceAccount.name
		}
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "server"
		}
		if #config.server.serviceAccount.annotations != _|_ {
			annotations: #config.server.serviceAccount.annotations
		}
	}
}
