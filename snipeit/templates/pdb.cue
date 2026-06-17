package templates

import policyv1 "k8s.io/api/policy/v1"

#PodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:   #config.metadata.name
		namespace: #config.metadata.namespace
		labels: #config._labels
	}
	spec: {
		selector: matchLabels: #config._pdbSelector
		if #config.pdb.maxUnavailable != _|_ {
			maxUnavailable: #config.pdb.maxUnavailable
		}
		if #config.pdb.maxUnavailable == _|_ && #config.maxUnavailable != _|_ {
			maxUnavailable: #config.maxUnavailable
		}
		if #config.pdb.maxUnavailable == _|_ && #config.maxUnavailable == _|_ {
			maxUnavailable: 0
		}
	}
}