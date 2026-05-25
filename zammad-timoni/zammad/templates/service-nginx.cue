package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceNginx: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-nginx"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.service.type
		ports: [
			{
				port:        #config.service.port
				targetPort:  "http"
				protocol:    "TCP"
				name:        "http"
				appProtocol: #config.service.appProtocol
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "zammad-nginx"
		}
	}
}
