package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PdbWs: policyv1.#PodDisruptionBudget & {
	#config:    #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-ws-pdb"
		namespace: #config.metadata.namespace
		labels: {
			app:      "\(#config.metadata.name)-ws"
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		selector: matchLabels: {
			app:     "\(#config.metadata.name)-ws"
			release: #config.metadata.name
		}
		if #config.supersetWebsockets.podDisruptionBudget.minAvailable != null {
			minAvailable: #config.supersetWebsockets.podDisruptionBudget.minAvailable
		}
		if #config.supersetWebsockets.podDisruptionBudget.maxUnavailable != null {
			maxUnavailable: #config.supersetWebsockets.podDisruptionBudget.maxUnavailable
		}
	}
}
