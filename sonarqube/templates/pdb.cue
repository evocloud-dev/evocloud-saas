package templates

import (
	policyv1 "k8s.io/api/policy/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#PodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config:    #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "sonarqube"
	}
	metadata: {
		name: #config.fullname
		labels: "app.kubernetes.io/component": "sonarqube"
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		minAvailable: #config.pdb.minAvailable
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "sonarqube"
		}
	}
}
