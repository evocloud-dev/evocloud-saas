package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PDB: policyv1.#PodDisruptionBudget & {
	#config: #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		if #config.drupal.podDisruptionBudget.minAvailable != _|_ {
			minAvailable: #config.drupal.podDisruptionBudget.minAvailable
		}
		if #config.drupal.podDisruptionBudget.maxUnavailable != _|_ {
			maxUnavailable: #config.drupal.podDisruptionBudget.maxUnavailable
		}
		selector: matchLabels: #config.selector.labels
	}
}
