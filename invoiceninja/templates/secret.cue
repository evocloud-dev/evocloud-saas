package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Secret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#secretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		APP_KEY:             #config.secret.appKey
		DB_PASSWORD:         #config.secret.dbPassword
		DB_ROOT_PASSWORD:    #config.secret.dbRootPassword
		MYSQL_PASSWORD:      #config.secret.dbPassword
		MYSQL_ROOT_PASSWORD: #config.secret.dbRootPassword
		REDIS_PASSWORD:      #config.secret.redisPassword
		IN_USER_EMAIL:       #config.secret.inUserEmail
		IN_PASSWORD:        #config.secret.inPassword
	}
}
