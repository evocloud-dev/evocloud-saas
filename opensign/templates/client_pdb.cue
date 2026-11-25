package templates

import (
	policyv1 "k8s.io/api/policy/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

#ClientPDB: policyv1.#PodDisruptionBudget & {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-client"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		if #config.client.podDisruptionBudget.minAvailable != "" {
			minAvailable: #config.client.podDisruptionBudget.minAvailable
		}
		if #config.client.podDisruptionBudget.maxUnavailable != "" {
			maxUnavailable: #config.client.podDisruptionBudget.maxUnavailable
		}
		selector: metav1.#LabelSelector & {
			matchLabels: {
				"app.kubernetes.io/name":     "opensign-client"
				"app.kubernetes.io/instance": #config.metadata.name
			}
		}
	}
}
