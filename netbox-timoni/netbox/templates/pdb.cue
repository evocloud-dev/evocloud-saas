package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PDB: policyv1.#PodDisruptionBudget & {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      #config._fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.commonAnnotations != _|_ {
			annotations: #config.commonAnnotations
		}
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.pdb.minAvailable != _|_ {
			minAvailable: #config.pdb.minAvailable
		}
		if #config.pdb.minAvailable == _|_ && #config.pdb.maxUnavailable != _|_ {
			maxUnavailable: #config.pdb.maxUnavailable
		}
	}
}

#WorkerPDB: policyv1.#PodDisruptionBudget & {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config._fullname)-worker"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "worker"
		}
		if #config.commonAnnotations != _|_ {
			annotations: #config.commonAnnotations
		}
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		selector: matchLabels: #config.worker.podLabels & {
			"app.kubernetes.io/component": "worker"
		}
		if #config.worker.pdb.minAvailable != _|_ {
			minAvailable: #config.worker.pdb.minAvailable
		}
		if #config.worker.pdb.minAvailable == _|_ && #config.worker.pdb.maxUnavailable != _|_ {
			maxUnavailable: #config.worker.pdb.maxUnavailable
		}
	}
}
