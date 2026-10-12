package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      #config.#hubFullname
		namespace: #config.metadata.namespace
		labels:    #config.#componentLabels & {#component: "hub"}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		minAvailable: #config.pdb.minAvailable
		selector: matchLabels: #config.#selectorLabels & {#component: "hub"}
	}
}
