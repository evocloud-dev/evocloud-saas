package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SecretRedis: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name: "\(#config.metadata.name)-redis"
		labels: #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"\(#config.redis.auth.existingSecretKey)": #config.redis.auth.password
	}
}
