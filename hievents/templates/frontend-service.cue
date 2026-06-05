package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#FrontendService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config._frontendName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "frontend"
		}
	}
	spec: {
		type: #config.frontend.service.type
		ports: [{
			name:       "http"
			port:       #config.frontend.service.port
			targetPort: #config.frontend.service.targetPort
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "frontend"
		}
	}
}
