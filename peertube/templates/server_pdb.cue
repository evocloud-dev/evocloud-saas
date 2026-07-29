package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#ServerPDB: policyv1.#PodDisruptionBudget & {
	#config:    #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      *"\((#config.metadata.name))-server" | string
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		if #config.server.podDisruptionBudget.minAvailable != null {
			minAvailable: #config.server.podDisruptionBudget.minAvailable
		}
		if #config.server.podDisruptionBudget.maxUnavailable != null {
			maxUnavailable: #config.server.podDisruptionBudget.maxUnavailable
		}
		if #config.server.podDisruptionBudget.unhealthyPodEvictionPolicy != null {
			unhealthyPodEvictionPolicy: #config.server.podDisruptionBudget.unhealthyPodEvictionPolicy
		}
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "server"
		}
	}
}
