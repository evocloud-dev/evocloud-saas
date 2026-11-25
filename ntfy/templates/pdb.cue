package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

// #PodDisruptionBudget mirrors templates/pdb.yaml.
#PodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		if #config.podDisruptionBudget.minAvailable != null {
			minAvailable: #config.podDisruptionBudget.minAvailable
		}
		if #config.podDisruptionBudget.minAvailable == null && #config.podDisruptionBudget.maxUnavailable != null {
			maxUnavailable: #config.podDisruptionBudget.maxUnavailable
		}
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "server"
		}
	}
}
