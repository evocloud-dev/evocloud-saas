package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServerService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "server"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		selector: {
			"app.kubernetes.io/name":     "opensign-server"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		ports: [{
			name:       "http"
			port:       #config.server.port
			targetPort: #config.server.port
			protocol:   "TCP"
		}]
	}
}
