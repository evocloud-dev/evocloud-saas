package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#RunnerHeadlessService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      *"\((#config.metadata.name))-runner-headless" | string
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "runner"
		}
		if #config.runner.service.annotations != _|_ {
			annotations: #config.runner.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		clusterIP: "None"
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "runner"
		}
	}
}
