package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ClientService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "client"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		selector: {
			"app.kubernetes.io/name":     "opensign-client"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		ports: [{
			name:       "http"
			port:       #config.client.port
			targetPort: #config.client.port
			protocol:   "TCP"
		}]
	}
}
