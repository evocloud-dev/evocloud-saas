package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SecretBackend: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-backend"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"secret-key":      #config.backend.config.secretKey
		"jwt-signing-key": #config.backend.config.jwtSigningKey
	}
}
