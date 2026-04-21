package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#HocuspocusNetworkPolicy: networkingv1.#NetworkPolicy & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(#config.metadata.name)-hocuspocus"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"openproject/process":        "hocuspocus"
			"app.kubernetes.io/component": "hocuspocus"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: networkingv1.#NetworkPolicySpec & {
		podSelector: matchLabels: #config.selector.labels & {
			"openproject/process":        "hocuspocus"
			"app.kubernetes.io/component": "hocuspocus"
		}
		policyTypes: ["Ingress", "Egress"]
		egress: [
			if #config.hocuspocus.networkPolicy.allowExternalEgress {
				{}
			},
			if !#config.hocuspocus.networkPolicy.allowExternalEgress {
				{
					ports: [
						{port: 53, protocol: "UDP"},
						{port: 53, protocol: "TCP"},
					]
				}
			},
			if !#config.hocuspocus.networkPolicy.allowExternalEgress && #config.hocuspocus.networkPolicy.extraEgress != _|_ {
				for e in #config.hocuspocus.networkPolicy.extraEgress {
					e
				}
			},
		]
		ingress: [
			{
				ports: [{port: 1234}]
				if !#config.hocuspocus.networkPolicy.allowExternal {
					from: [
						{podSelector: matchLabels: #config.selector.labels},
						if #config.hocuspocus.networkPolicy.addExternalClientAccess {
							{podSelector: matchLabels: {"\(#config.metadata.name)-client": "true"}}
						},
						if #config.hocuspocus.networkPolicy.ingressPodMatchLabels != _|_ {
							{podSelector: matchLabels: #config.hocuspocus.networkPolicy.ingressPodMatchLabels}
						},
						if #config.hocuspocus.networkPolicy.ingressNSMatchLabels != _|_ {
							{
								namespaceSelector: matchLabels: #config.hocuspocus.networkPolicy.ingressNSMatchLabels
								if #config.hocuspocus.networkPolicy.ingressNSPodMatchLabels != _|_ {
									podSelector: matchLabels: #config.hocuspocus.networkPolicy.ingressNSPodMatchLabels
								}
							}
						},
					]
				}
			},
			if #config.hocuspocus.networkPolicy.extraIngress != _|_ {
				for i in #config.hocuspocus.networkPolicy.extraIngress {
					i
				}
			},
		]
	}
}
