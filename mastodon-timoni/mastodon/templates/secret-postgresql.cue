package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SecretPostgresql: corev1.#Secret & {
	#config: #Config
	#name:   "\(#config.metadata.name)-postgresql"

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name:      #name
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		password: #config.postgresql.auth.password
	}
}
