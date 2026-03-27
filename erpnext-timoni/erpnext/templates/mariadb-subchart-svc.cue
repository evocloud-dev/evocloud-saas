package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#MariaDBSubchartSVC: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-mariadb"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [
			{
				name:       "mariadb"
				port:       3306
				targetPort: 3306
				protocol:   "TCP"
			},
		]
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-mariadb"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}