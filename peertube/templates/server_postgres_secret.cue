package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServerPostgresSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      *"\((#config.metadata.name))-server-postgres" | string
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "server"
		}
	}
	type: "Opaque"
	stringData: {
		"postgres-username": {
			if #config.server.externalPostgres.username != "" {
				#config.server.externalPostgres.username
			}
			if #config.server.externalPostgres.username == "" {
				"peertube"
			}
		}
		"postgres-password": {
			if #config.server.externalPostgres.password != "" {
				#config.server.externalPostgres.password
			}
			if #config.server.externalPostgres.password == "" {
				"peertubepassword"
			}
		}
	}
}
