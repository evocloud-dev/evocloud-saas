package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#OIDCSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.oidcSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		(#config.oidc.clientSecretKey): #config.oidc.clientSecret
	}
}

