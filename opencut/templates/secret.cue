package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Secret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#secretName
		namespace: #config.metadata.namespace
		labels:    #config.#allLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		"better-auth-secret": #config.#betterAuthSecret
		"redis-rest-token":   #config.#redisRestToken
		if #config.redis.external.host != "" && #config.redis.external.password != "" && #config.redis.external.existingSecret == "" {
			"redis-password": #config.redis.external.password
		}
		"marble-workspace-key": #config.opencut.marbleWorkspaceKey
		"freesound-client-id":  #config.opencut.freesoundClientId
		"freesound-api-key":    #config.opencut.freesoundApiKey
	}
}

#DatabaseSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.#fullname)-database"
		namespace: #config.metadata.namespace
		labels:    #config.#allLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		"database-password": #config.database.external.password
	}
}
