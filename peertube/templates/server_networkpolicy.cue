package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#ServerNetworkPolicy: networkingv1.#NetworkPolicy & {
	#config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      *"\((#config.metadata.name))-server" | string
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: networkingv1.#NetworkPolicySpec & {
		podSelector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "server"
		}
		policyTypes: [
			if len(#config.server.networkPolicy.ingress) > 0 {
				"Ingress"
			},
			if len(#config.server.networkPolicy.egress) > 0 {
				"Egress"
			},
		]
		if len(#config.server.networkPolicy.ingress) > 0 {
			ingress: #config.server.networkPolicy.ingress
		}
		if len(#config.server.networkPolicy.egress) > 0 {
			egress: #config.server.networkPolicy.egress
		}
	}
}
