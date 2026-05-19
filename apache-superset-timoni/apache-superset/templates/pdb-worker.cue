package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PdbWorker: policyv1.#PodDisruptionBudget & {
	#config:    #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-worker-pdb"
		namespace: #config.metadata.namespace
		labels: {
			app:      "\(#config.metadata.name)-worker"
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		selector: matchLabels: {
			app:     "\(#config.metadata.name)-worker"
			release: #config.metadata.name
		}
		if #config.supersetWorker.podDisruptionBudget.minAvailable != null {
			minAvailable: #config.supersetWorker.podDisruptionBudget.minAvailable
		}
		if #config.supersetWorker.podDisruptionBudget.maxUnavailable != null {
			maxUnavailable: #config.supersetWorker.podDisruptionBudget.maxUnavailable
		}
	}
}
