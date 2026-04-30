package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#AppSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-app-secrets"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "secrets"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		APP_ID:            #config.secrets.APP_ID
		APP_KEY:           #config.secrets.APP_KEY
		DB_USERNAME:       #config.secrets.DB_USERNAME
		DB_PASSWORD:       #config.secrets.DB_PASSWORD
		REDIS_PASSWORD:    #config.secrets.REDIS_PASSWORD
		PUSHER_APP_ID:     #config.secrets.PUSHER_APP_ID
		PUSHER_APP_KEY:    #config.secrets.PUSHER_APP_KEY
		PUSHER_APP_SECRET: #config.secrets.PUSHER_APP_SECRET
		if #config.secrets.ROOT_USERNAME != "" {
			ROOT_USERNAME: #config.secrets.ROOT_USERNAME
		}
		if #config.secrets.ROOT_USER_EMAIL != "" {
			ROOT_USER_EMAIL: #config.secrets.ROOT_USER_EMAIL
		}
		if #config.secrets.ROOT_USER_PASSWORD != "" {
			ROOT_USER_PASSWORD: #config.secrets.ROOT_USER_PASSWORD
		}
	}
}
