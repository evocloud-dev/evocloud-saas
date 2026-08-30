package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ExternalRedisSecret: corev1.#Secret & {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "ext-redis-\(#config.metadata.name)"
		namespace: #config.metadata.namespace
	}
	stringData: {
		host: app.externalRedis.host
		port: "\(app.externalRedis.port)"
		if app.externalRedis.auth.enabled {
			if app.externalRedis.auth.username != _|_ {
				username: app.externalRedis.auth.username
			}
			if app.externalRedis.auth.password != _|_ {
				password: app.externalRedis.auth.password
			}
		}
	}
}
