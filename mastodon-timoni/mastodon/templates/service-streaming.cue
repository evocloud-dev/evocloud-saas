package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceStreaming: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name: "\(#config.metadata.name)-streaming"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "streaming"
		}
		if #config.mastodon.streaming.service.annotations != _|_ {
			annotations: #config.mastodon.streaming.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.service.type
		ports: [
			{
				name:       "streaming"
				port:       #config.mastodon.streaming.port
				targetPort: "streaming"
				protocol:   "TCP"
			},
		]
		ipFamilyPolicy: "PreferDualStack"
		selector: {
			#config.selector.labels
			"app.kubernetes.io/component": "streaming"
		}
	}
}
