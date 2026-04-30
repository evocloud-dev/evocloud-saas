package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#RedisSecret: {
	#config: #Config
	if #config.redis.enabled {
		secret: corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(#config.metadata.name)-redis"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels & {
					"app.kubernetes.io/component": "redis"
				}
				if #config.metadata.annotations != _|_ {
					annotations: #config.metadata.annotations
				}
			}
			type: "Opaque"
			stringData: {
				"redis-password": #config.redis.auth.password
			}
		}
	}
}
