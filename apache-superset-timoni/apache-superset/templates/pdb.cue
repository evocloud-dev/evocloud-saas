package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#Pdb: policyv1.#PodDisruptionBudget & {
	#config:    #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-pdb"
		namespace: #config.metadata.namespace
		labels: {
			app:      #config.metadata.name
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		selector: matchLabels: {
			app:     #config.metadata.name
			release: #config.metadata.name
		}
		if #config.supersetNode.podDisruptionBudget.minAvailable != null {
			minAvailable: #config.supersetNode.podDisruptionBudget.minAvailable
		}
		if #config.supersetNode.podDisruptionBudget.maxUnavailable != null {
			maxUnavailable: #config.supersetNode.podDisruptionBudget.maxUnavailable
		}
	}
}
