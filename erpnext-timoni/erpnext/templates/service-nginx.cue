package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#NginxService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: #config.nginx.service.type
		ports: [
			{
				port:       #config.nginx.service.port
				targetPort: "http"
				protocol:   "TCP"
				name:       "http"
			},
		]
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.labels["app.kubernetes.io/name"])-nginx"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}
