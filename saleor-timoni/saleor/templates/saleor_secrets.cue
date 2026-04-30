package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Secret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-secrets"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type:       "Opaque"
	stringData: {
		"secret-key":           #config.global.secretKey
		"database-url":         #config.#internal.databaseUrl
		"database-url-replica": #config.#internal.databaseReplicaUrl
		"redis-url":            #config.#internal.redisUrl
		"celery-redis-url":     #config.#internal.celeryRedisUrl
		if #config.global.jwtRsaPrivateKey != _|_ {
			"jwt-private-key": #config.global.jwtRsaPrivateKey
		}
		if #config.global.jwtRsaPublicKey != _|_ {
			"jwt-public-key": #config.global.jwtRsaPublicKey
		}
		for k, v in #config.global.extraSecrets {
			"\(k)": v
		}
	}
}
