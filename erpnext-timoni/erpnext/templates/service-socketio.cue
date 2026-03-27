package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SocketioService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-socketio"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: #config.socketio.service.type
		ports: [
			{
				port:       #config.socketio.service.port
				targetPort: "http"
				protocol:   "TCP"
				name:       "http"
			},
		]
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.labels["app.kubernetes.io/name"])-socketio"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}
