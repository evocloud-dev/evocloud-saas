package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DbUrlSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name: "\(#config.metadata.name)-db-url"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "db"
		}
	}
	type: "Opaque"
	stringData: {
		url:         "postgres://\(#config.db.internal.appUser):\(#config.db.internal.appPassword)@\(#config.metadata.name)-db:5432/\(#config.db.internal.database)"
		appPassword: #config.db.internal.appPassword
	}
}
