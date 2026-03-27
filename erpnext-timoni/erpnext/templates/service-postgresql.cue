package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQLService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-sts"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [
			{
				port:       5432
				targetPort: "postgresql"
				protocol:   "TCP"
				name:       "postgresql"
			},
		]
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-postgresql-sts"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}
