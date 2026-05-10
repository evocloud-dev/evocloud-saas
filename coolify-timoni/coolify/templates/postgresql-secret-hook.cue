package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQLSecret: {
	#config: #Config
	if #config.postgresql.enabled {
		secret: corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(#config.metadata.name)-postgresql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels & {
					"app.kubernetes.io/component": "postgresql"
				}
				if #config.metadata.annotations != _|_ {
					annotations: #config.metadata.annotations
				}
			}
			type: "Opaque"
			stringData: {
				"postgres-password": #config.postgresql.auth.postgresPassword
				"password":          #config.postgresql.auth.password
			}
		}
	}
}
