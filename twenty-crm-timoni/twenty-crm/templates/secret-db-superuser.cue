package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DbSuperuserSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name: "\(#config.metadata.name)-db-superuser"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "db"
		}
	}
	type: "Opaque"
	stringData: {
		username: #config.db.internal.env.PGUSER_SUPERUSER
		password: #config.db.internal.env.PGPASSWORD_SUPERUSER
	}
}
