package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

// PodDisruptionBudget mirrors templates/pdb.yaml
#PodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata:   #config.metadata & {name: #config.fullname}
	spec: {
		selector: matchLabels: #config.selector.labels
		
		if #config.podDisruptionBudget.minAvailable != null && #config.podDisruptionBudget.minAvailable != "" {
			minAvailable: #config.podDisruptionBudget.minAvailable
		}
		if #config.podDisruptionBudget.minAvailable == null || #config.podDisruptionBudget.minAvailable == "" {
			maxUnavailable: #config.podDisruptionBudget.maxUnavailable
		}
	}
}
