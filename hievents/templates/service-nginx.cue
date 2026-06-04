package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceNginx: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config._nginxServiceName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "nginx"
		}
	}
	spec: {
		type: #config.webProxy.service.type
		ports: [{
			name:       "http"
			port:       #config.webProxy.service.port
			targetPort: #config.webProxy.service.targetPort
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "nginx"
		}
	}
}
