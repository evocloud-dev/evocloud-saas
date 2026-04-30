package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#CoolifyAppPDB: {
	#config: #Config
	if #config.coolifyApp.podDisruptionBudget.enabled {
		pdb: policyv1.#PodDisruptionBudget & {
			apiVersion: "policy/v1"
			kind:       "PodDisruptionBudget"
			metadata: {
				name:      "\(#config.metadata.name)-app-pdb"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels & {
					"app.kubernetes.io/component": "core"
				}
				if #config.metadata.annotations != _|_ {
					annotations: #config.metadata.annotations
				}
			}
			spec: policyv1.#PodDisruptionBudgetSpec & {
				minAvailable: #config.coolifyApp.podDisruptionBudget.minAvailable
				selector: matchLabels: {
					"app.kubernetes.io/name":      #config.metadata.name
					"app.kubernetes.io/component": "core"
				}
			}
		}
	}
}
