package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#EnvironmentSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-environment"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "openproject"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		for k, v in #config.openproject.environment {
			"\(k)": "\(v)"
		}
	}
}
