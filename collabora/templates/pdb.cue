package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		if #config.podDisruptionBudget.minAvailable != _|_ {
			minAvailable: #config.podDisruptionBudget.minAvailable
		}
		if #config.podDisruptionBudget.maxUnavailable != _|_ {
			maxUnavailable: #config.podDisruptionBudget.maxUnavailable
		}
		selector: matchLabels: #config.selector.labels
	}
}

