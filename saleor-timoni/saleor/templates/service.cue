package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#APIService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-api"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "api"
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.api.service.type
		selector: (timoniv1.#Selector & {#Name: "\(#config.metadata.name)-api"}).labels & {
			"app.kubernetes.io/component": "api"
		}
		ports: [
			{
				name:       "http"
				port:       #config.api.service.port
				targetPort: 8000
				protocol:   "TCP"
			},
		]
	}
}
