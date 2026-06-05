package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#BackendService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config._backendName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "backend"
		}
	}
	spec: {
		type: #config.backend.service.type
		ports: [{
			name:       "http"
			port:       #config.backend.service.port
			targetPort: #config.backend.service.targetPort
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "backend"
		}
	}
}
