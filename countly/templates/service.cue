package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata:   #config.metadata
	if #config.service.annotations != _|_ {
		metadata: annotations: #config.service.annotations
	}
	spec: corev1.#ServiceSpec & {
		type: #config.service.type
		if #config.service.ipFamilyPolicy != _|_ && #config.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if #config.service.ipFamilies != _|_ && len(#config.service.ipFamilies) > 0 {
			ipFamilies: #config.service.ipFamilies
		}
		ports: [
			{
				name: "http"
				port: #config.service.port
				protocol: "TCP"
				targetPort: "dashboard"
			},
			{
				name: "api"
				port: #config.service.apiPort
				protocol: "TCP"
				targetPort: "api"
			},
		]
		selector: #config.selector.labels
	}
}
