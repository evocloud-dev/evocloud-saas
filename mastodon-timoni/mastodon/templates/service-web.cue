package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceWeb: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-web"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "web"
			"app.kubernetes.io/part-of":    "rails"
		}
		if #config.mastodon.web.service.annotations != _|_ {
			annotations: #config.mastodon.web.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.service.type
		ports: [
			{
				name:       "http"
				port:       #config.mastodon.web.port
				targetPort: "http"
				protocol:   "TCP"
			},
		]
		ipFamilyPolicy: "PreferDualStack"
		selector: {
			#config.selector.labels
			"app.kubernetes.io/component": "web"
			"app.kubernetes.io/part-of":    "rails"
		}
	}
}
