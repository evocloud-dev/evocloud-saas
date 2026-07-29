package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#RunnerPDB: policyv1.#PodDisruptionBudget & {
	#config:    #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      *"\((#config.metadata.name))-runner" | string
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "runner"
		}
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		if #config.runner.podDisruptionBudget.minAvailable != null {
			minAvailable: #config.runner.podDisruptionBudget.minAvailable
		}
		if #config.runner.podDisruptionBudget.maxUnavailable != null {
			maxUnavailable: #config.runner.podDisruptionBudget.maxUnavailable
		}
		if #config.runner.podDisruptionBudget.unhealthyPodEvictionPolicy != null {
			unhealthyPodEvictionPolicy: #config.runner.podDisruptionBudget.unhealthyPodEvictionPolicy
		}
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "runner"
		}
	}
}
