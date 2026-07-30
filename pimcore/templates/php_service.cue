package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServicePhp: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-php"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		type: #config.php.service.type
		ports: [
			{
				port:       9000
				targetPort: 9000
			},
		]
		selector: {
			"app.kubernetes.io/name":     #config.metadata.name
			"app.kubernetes.io/instance": "\(#config.metadata.name)-php"
		}
	}
}
