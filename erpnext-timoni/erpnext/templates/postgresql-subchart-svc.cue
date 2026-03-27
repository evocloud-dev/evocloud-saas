package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQLSubchartSVC: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [
			{
				name:       "postgresql"
				port:       5432
				targetPort: 5432
				protocol:   "TCP"
			},
		]
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}
