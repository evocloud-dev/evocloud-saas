package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#NetworkPolicy: networkingv1.#NetworkPolicy & {
	#config: #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		#name:     string
		name:      "\(#config.metadata.name)-\(#name)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
}

#AllowSameNS: #NetworkPolicy & {
	#name: "allow-same-ns"
	spec: networkingv1.#NetworkPolicySpec & {
		podSelector: {}
		ingress: [{
			from: [{
				podSelector: {}
			}]
		}]
	}
}

#AllowOpenShiftIngress: #NetworkPolicy & {
	#name: "allow-openshift-ingress"
	spec: networkingv1.#NetworkPolicySpec & {
		podSelector: {}
		ingress: [{
			from: [{
				namespaceSelector: matchLabels: {
					"network.openshift.io/policy-group": "ingress"
				}
			}]
		}]
		policyTypes: ["Ingress"]
	}
}
