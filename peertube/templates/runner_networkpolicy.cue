package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#RunnerNetworkPolicy: networkingv1.#NetworkPolicy & {
	#config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      *"\((#config.metadata.name))-runner" | string
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "runner"
		}
	}
	spec: networkingv1.#NetworkPolicySpec & {
		podSelector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "runner"
		}
		policyTypes: [
			if len(#config.runner.networkPolicy.ingress) > 0 {
				"Ingress"
			},
			if len(#config.runner.networkPolicy.egress) > 0 {
				"Egress"
			},
		]
		if len(#config.runner.networkPolicy.ingress) > 0 {
			ingress: #config.runner.networkPolicy.ingress
		}
		if len(#config.runner.networkPolicy.egress) > 0 {
			egress: #config.runner.networkPolicy.egress
		}
	}
}
