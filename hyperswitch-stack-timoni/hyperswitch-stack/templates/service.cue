package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.service.annotations != _|_ {
			annotations: #config.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		internalTrafficPolicy: "Cluster"
		ipFamilies: ["IPv4"]
		ipFamilyPolicy: "SingleStack"
		ports: [
			{
				name:       "http"
				port:       80
				protocol:   "TCP"
				targetPort: 8080
			},
			{
				name:       "https"
				port:       443
				protocol:   "TCP"
				targetPort: 8080
			},
		]
		selector: {
			app:                          #config.metadata.name
			"app.kubernetes.io/instance": #config.metadata.name
		}
		sessionAffinity: "None"
		type:            "ClusterIP"
	}
}
