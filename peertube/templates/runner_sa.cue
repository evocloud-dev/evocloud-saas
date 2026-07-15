package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#RunnerServiceAccount: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name: *"\((#config.metadata.name))-runner" | string
		if #config.runner.serviceAccount.name != "" {
			name: #config.runner.serviceAccount.name
		}
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "runner"
		}
		if #config.runner.serviceAccount.annotations != _|_ {
			annotations: #config.runner.serviceAccount.annotations
		}
	}
}
