package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#CaddyService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "caddy"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: #config.caddy.serviceType
		selector: {
			"app.kubernetes.io/name":     "opensign-caddy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		ports: [
			{name: "http", port: 80, targetPort: 80, protocol: "TCP"},
			{name: "https", port: 443, targetPort: 443, protocol: "TCP"},
			{name: "https-udp", port: 443, targetPort: 443, protocol: "UDP"},
			{name: "alt", port: 3001, targetPort: 3001, protocol: "TCP"},
		]
	}
}
