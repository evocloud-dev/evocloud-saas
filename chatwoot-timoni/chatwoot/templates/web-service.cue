package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#WebService: {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.services.annotations != _|_ {
			annotations: #config.services.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.services.type
		ports: [{
			name:       #config.services.name
			port:       #config.services.internalPort
			targetPort: #config.services.targetPort
		}]
		selector: {
			app:  #config.metadata.name
			role: "web"
		}
	}
}
