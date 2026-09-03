package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PosthogAssetsProxyService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.posthog.fullname)-assets-proxy"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.posthog.assetsService.annotations != _|_ {
			annotations: #config.posthog.assetsService.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.posthog.assetsService.type
		if #config.posthog.assetsService.type == "ExternalName" {
			externalName: #config.posthog.assetsService.externalName
		}
		ports: [{
			name:       "http"
			port:       #config.posthog.assetsService.port
			targetPort: #config.posthog.assetsService.targetPort
			protocol:   "TCP"
		}]
		// Selector is usually omitted for ExternalName services, but kept here to match your Helm logic
		selector: #config.selector.labels
	}
}