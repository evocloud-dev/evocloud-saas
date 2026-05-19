package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PdbFlower: policyv1.#PodDisruptionBudget & {
	#config:    #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-flower-pdb"
		namespace: #config.metadata.namespace
		labels: {
			app:      "\(#config.metadata.name)-flower"
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		selector: matchLabels: {
			app:     "\(#config.metadata.name)-flower"
			release: #config.metadata.name
		}
		if #config.supersetCeleryFlower.podDisruptionBudget.minAvailable != null {
			minAvailable: #config.supersetCeleryFlower.podDisruptionBudget.minAvailable
		}
		if #config.supersetCeleryFlower.podDisruptionBudget.maxUnavailable != null {
			maxUnavailable: #config.supersetCeleryFlower.podDisruptionBudget.maxUnavailable
		}
	}
}
