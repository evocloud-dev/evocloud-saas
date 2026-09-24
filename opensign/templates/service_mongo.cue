package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#MongoService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "mongo"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		selector: {
			"app.kubernetes.io/name":     "opensign-mongo"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		ports: [{
			name:       "mongodb"
			port:       #config.mongodb.port
			targetPort: #config.mongodb.port
			protocol:   "TCP"
		}]
	}
}
