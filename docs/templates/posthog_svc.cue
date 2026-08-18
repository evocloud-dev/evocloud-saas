package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PosthogProxyService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.posthog.fullname)-proxy"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.posthog.service.annotations != _|_ {
			annotations: #config.posthog.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.posthog.service.type
		if #config.posthog.service.type == "ExternalName" {
			externalName: #config.posthog.service.externalName
		}
		ports: [{
			name:       "https"
			port:       #config.posthog.service.port
			targetPort: #config.posthog.service.targetPort
			protocol:   "TCP"
		}]
		selector: #config.selector.labels
	}
}