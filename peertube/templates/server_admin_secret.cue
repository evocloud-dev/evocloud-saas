package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServerAdminSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      *"\((#config.metadata.name))-server-admin" | string
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "server"
		}
	}
	type: "Opaque"
	stringData: {
		"admin-password": #config.server.config.admin.password
	}
}
