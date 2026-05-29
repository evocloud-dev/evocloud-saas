package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PdbBeat: policyv1.#PodDisruptionBudget & {
	#config:    #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-celerybeat-pdb"
		namespace: #config.metadata.namespace
		labels: {
			app:      "\(#config.metadata.name)-celerybeat"
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		selector: matchLabels: {
			app:     "\(#config.metadata.name)-celerybeat"
			release: #config.metadata.name
		}
		if #config.supersetCeleryBeat.podDisruptionBudget.minAvailable != null {
			minAvailable: #config.supersetCeleryBeat.podDisruptionBudget.minAvailable
		}
		if #config.supersetCeleryBeat.podDisruptionBudget.maxUnavailable != null {
			maxUnavailable: #config.supersetCeleryBeat.podDisruptionBudget.maxUnavailable
		}
	}
}
