package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PodDisruptionBudget: {
	#config: #Config
	#helpers: #Helpers

	listmonk: {
		apiVersion: "policy/v1"
		kind:       "PodDisruptionBudget"
		metadata: {
			name:      #helpers.fullname
			namespace: #config.metadata.namespace
			labels:    #helpers.labels
		}
		spec: policyv1.#PodDisruptionBudgetSpec & {
			minAvailable: #config.podDisruptionBudget.minAvailable
			selector: matchLabels: #helpers.selectorLabels
		}
	}

	postgres: {
		apiVersion: "policy/v1"
		kind:       "PodDisruptionBudget"
		metadata: {
			name:      #helpers.postgresStatefulSetName
			namespace: #config.metadata.namespace
			labels:    #helpers.labels
		}
		spec: policyv1.#PodDisruptionBudgetSpec & {
			minAvailable: #config.postgres.podDisruptionBudget.minAvailable
			selector: matchLabels: {
				"app.kubernetes.io/name":     #helpers.postgresStatefulSetName
				"app.kubernetes.io/instance": #config.metadata.name
			}
		}
	}
}
