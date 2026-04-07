package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DatabaseService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name: "\(#config.metadata.name)-db"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "db"
		}
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		selector: {
			"app.kubernetes.io/name":      #config.metadata.name
			"app.kubernetes.io/component": "db"
		}
		ports: [
			{
				port:       5432
				targetPort: 5432
				protocol:   "TCP"
				name:       "postgres"
			},
		]
	}
}
