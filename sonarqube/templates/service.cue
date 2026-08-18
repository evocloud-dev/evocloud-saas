package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Service: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "sonarqube"
	}
	metadata: {
		name: #config.fullname
		labels: "app.kubernetes.io/component": "sonarqube"
		if #config.service.annotations != _|_ {
			annotations: #config.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.service.type
		if #config.service.ipFamilyPolicy != _|_ if #config.service.ipFamilyPolicy != null {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if #config.service.ipFamilies != _|_ {
			ipFamilies: #config.service.ipFamilies
		}
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "sonarqube"
		}
		ports: [
			{
				name:       "http"
				port:       #config.service.port
				targetPort: "http"
				protocol:   "TCP"
			},
		]
	}
}
