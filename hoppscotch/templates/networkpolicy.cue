package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#NetworkPolicy: networkingv1.#NetworkPolicy & {
	#config: #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      #config.fullname
		namespace: #config.namespace
		labels:    #config.labels
	}
	spec: {
		podSelector: matchLabels: #config.selectorLabels
		policyTypes: ["Ingress", "Egress"]
		ingress: [
			{
				from: [
					{
						podSelector: {}
					},
				]
				ports: [
					{
						port:     "http"
						protocol: "TCP"
					},
				]
			},
			for i in #config.networkPolicy.ingress {
				i
			},
		]
		egress: [
			{
				ports: [
					{
						port:     53
						protocol: "UDP"
					},
					{
						port:     53
						protocol: "TCP"
					},
				]
			},
			{
				ports: [
					{
						port:     #config.databasePort
						protocol: "TCP"
					},
				]
			},
			for e in #config.networkPolicy.egress {
				e
			},
		]
	}
}
