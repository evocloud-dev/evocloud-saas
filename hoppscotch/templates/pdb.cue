package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      #config.fullname
		namespace: #config.namespace
		labels:    #config.labels
	}
	spec: {
		minAvailable: #config.podDisruptionBudget.minAvailable
		selector: matchLabels: #config.selectorLabels
	}
}
