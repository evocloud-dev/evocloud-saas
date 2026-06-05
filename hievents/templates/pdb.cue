package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#BackendPDB: policyv1.#PodDisruptionBudget & {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      #config._backendName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "backend"
		}
	}
	spec: {
		minAvailable: #config.backend.pdb.minAvailable
		selector: matchLabels: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "backend"
		}
	}
}

#FrontendPDB: policyv1.#PodDisruptionBudget & {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      #config._frontendName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "frontend"
		}
	}
	spec: {
		minAvailable: #config.frontend.pdb.minAvailable
		selector: matchLabels: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "frontend"
		}
	}
}
