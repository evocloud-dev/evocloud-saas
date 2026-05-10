package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#CoolifyAppService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-app-svc"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "core"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.coolifyApp.service.type
		ports: [
			{
				name:       "http"
				port:       #config.coolifyApp.service.port
				targetPort: #config.coolifyApp.service.targetPort
				protocol:   "TCP"
			},
		]
		selector: {
			"app.kubernetes.io/name":      #config.metadata.name
			"app.kubernetes.io/component": "core"
		}
	}
}
