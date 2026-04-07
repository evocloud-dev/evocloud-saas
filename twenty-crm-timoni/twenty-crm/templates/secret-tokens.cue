package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#TokensSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name: "\(#config.metadata.name)-\(#config.secrets.tokens.name)"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "secrets"
		}
	}
	type: "Opaque"
	stringData: {
		accessToken: #config.secrets.tokens.accessToken
	}
}
