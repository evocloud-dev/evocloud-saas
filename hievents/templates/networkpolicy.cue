package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#NetworkPolicy: networkingv1.NetworkPolicy & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      #config._fullname
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels
	}
	spec: {
		podSelector: matchLabels: {
			"app.kubernetes.io/name":     #config._appName
			"app.kubernetes.io/instance":  #config.metadata.name
		}
		ingress: [{
			from: [{
				podSelector: {}
			}]
		}]
		egress: [{}]
		policyTypes: ["Ingress", "Egress"]
	}
}
