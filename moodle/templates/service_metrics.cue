package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceMetrics: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#metricsServiceName
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
			"app.kubernetes.io/component": "metrics"
		}
	}
	spec: {
		type: "ClusterIP"
		if #config.service.ipFamilyPolicy != _|_ {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if #config.service.ipFamilies != _|_ {
			ipFamilies: #config.service.ipFamilies
		}
		selector: #config.#selectorLabels
		ports: [
			{
				name:       "metrics"
				port:       9090
				targetPort: "metrics"
				protocol:   "TCP"
			},
		]
	}
}

