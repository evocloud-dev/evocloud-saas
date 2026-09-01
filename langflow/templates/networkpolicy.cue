// SPDX-License-Identifier: Apache-2.0
package templates

import (
	netv1 "k8s.io/api/networking/v1"
)

#NetworkPolicyBuilder: {
	_config:   #Config
	_fullname: string

	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      _fullname
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	spec: netv1.#NetworkPolicySpec & {
		podSelector: matchLabels: _config.metadata.labels
		policyTypes: ["Ingress", "Egress"]
		ingress: [{
			from: [
				if len(_config.networkPolicy.ingressFrom) > 0
				for item in _config.networkPolicy.ingressFrom {item},
				if len(_config.networkPolicy.ingressFrom) == 0 {
					namespaceSelector: {}
				},
			]
			ports: [{
				protocol: "TCP"
				port:     "http"
			}]
		}]
		egress: [
			{
				to: [for peer in _config.networkPolicy.dnsEgressPeers {peer}]
				ports: [
					{protocol: "UDP", port: 53},
					{protocol: "TCP", port: 53},
				]
			},
			{
				to: [
					{ipBlock: cidr: "0.0.0.0/0"},
					{ipBlock: cidr: "::/0"},
				]
				ports: [{protocol: "TCP", port: 443}]
			},
			for rule in _config.networkPolicy.extraEgress {rule},
		]
	}
}
