package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#AppSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#secretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		"secret-key-base": #config.#secretKeyBaseValue
	}
}

#DatabaseSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#dbSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		"database-password": #config.database.external.password
	}
}

#RedisSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#redisSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		"redis-password": #config.redis.external.password
	}
}
