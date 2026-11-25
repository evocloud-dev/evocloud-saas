package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels:    #config.#labels
		if len(#config.#pdbAnnotations) > 0 {
			annotations: #config.#pdbAnnotations
		}
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		minAvailable: #config.podDisruptionBudget.minAvailable
		selector: matchLabels: #config.#selector
	}
}
