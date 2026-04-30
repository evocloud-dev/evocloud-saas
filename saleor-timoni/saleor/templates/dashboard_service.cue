package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#DashboardService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-dashboard"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "dashboard"
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.dashboard.service.type
		selector: (timoniv1.#Selector & {#Name: "\(#config.metadata.name)-dashboard"}).labels & {
			"app.kubernetes.io/component": "dashboard"
		}
		ports: [
			{
				name:       "http"
				port:       #config.dashboard.service.port
				targetPort: 80
				protocol:   "TCP"
			},
		]
	}
}
