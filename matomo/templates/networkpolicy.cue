package templates

import (
	netv1 "k8s.io/api/networking/v1"
)

// NetworkPolicy mirrors templates/networkpolicy.yaml
#NetworkPolicy: netv1.#NetworkPolicy & {
	#config: #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata:   #config.metadata & {name: #config.fullname}
	spec: {
		podSelector: matchLabels: #config.selector.labels
		policyTypes: [
			"Ingress",
			if #config.networkPolicy.egress.enabled != _|_ && #config.networkPolicy.egress.enabled { "Egress" },
		]
		ingress: [{
			if #config.networkPolicy.ingressFrom != _|_ && #config.networkPolicy.ingressFrom != [] {
				from: #config.networkPolicy.ingressFrom
			}
			if #config.networkPolicy.ingressFrom == _|_ || #config.networkPolicy.ingressFrom == [] {
				from: [{namespaceSelector: {}}]
			}
			ports: [{protocol: "TCP", port: "http"}]
		}]
		if #config.networkPolicy.egress.enabled != _|_ && #config.networkPolicy.egress.enabled {
			egress: [{
				// DNS allow block combined with Database port into one ports array
				ports: [
					if #config.networkPolicy.egress.allowDNS != _|_ && #config.networkPolicy.egress.allowDNS { {protocol: "UDP", port: 53} },
					if #config.networkPolicy.egress.allowDNS != _|_ && #config.networkPolicy.egress.allowDNS { {protocol: "TCP", port: 53} },
					{protocol: "TCP", port: #config.database.external.port},
				]
			}]
		}
	}
}
