package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#WorkerNetworkPolicy: networkingv1.#NetworkPolicy & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(#config.metadata.name)-worker"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"openproject/process":        "worker"
			"app.kubernetes.io/component": "worker"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: networkingv1.#NetworkPolicySpec & {
		podSelector: matchLabels: #config.selector.labels & {
			"openproject/process":        "worker"
			"app.kubernetes.io/component": "worker"
		}
		policyTypes: ["Ingress", "Egress"]
		egress: [
			if #config.networkPolicy.allowExternalEgress {
				{}
			},
			if !#config.networkPolicy.allowExternalEgress {
				{
					ports: [
						{port: 53, protocol: "UDP"},
						{port: 53, protocol: "TCP"},
					]
				}
			},
			if !#config.networkPolicy.allowExternalEgress && #config.networkPolicy.extraEgress != _|_ {
				for e in #config.networkPolicy.extraEgress {
					e
				}
			},
		]
		ingress: [
			{
				if !#config.networkPolicy.allowExternal {
					from: [
						{podSelector: matchLabels: #config.selector.labels},
						if #config.networkPolicy.addExternalClientAccess {
							{podSelector: matchLabels: {"\(#config.metadata.name)-client": "true"}}
						},
						if #config.networkPolicy.ingressPodMatchLabels != _|_ {
							{podSelector: matchLabels: #config.networkPolicy.ingressPodMatchLabels}
						},
						if #config.networkPolicy.ingressNSMatchLabels != _|_ {
							{
								namespaceSelector: matchLabels: #config.networkPolicy.ingressNSMatchLabels
								if #config.networkPolicy.ingressNSPodMatchLabels != _|_ {
									podSelector: matchLabels: #config.networkPolicy.ingressNSPodMatchLabels
								}
							}
						},
					]
				}
			},
			if #config.networkPolicy.extraIngress != _|_ {
				for i in #config.networkPolicy.extraIngress {
					i
				}
			},
		]
	}
}
