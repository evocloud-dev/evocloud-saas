package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata:   #config.metadata
	spec: policyv1.#PodDisruptionBudgetSpec & {
		maxUnavailable: #config.podDisruptionBudget.maxUnavailable
		selector: matchLabels: #config.selector.labels
	}
}

