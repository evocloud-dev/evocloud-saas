package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PdbStreaming: policyv1.#PodDisruptionBudget & {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		namespace: #config.#namespace
		name:   "\(#config.metadata.name)-streaming"
		labels: #config.metadata.labels
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		if #config.mastodon.streaming.pdb.minAvailable != _|_ {
			minAvailable: #config.mastodon.streaming.pdb.minAvailable
		}
		if #config.mastodon.streaming.pdb.minAvailable == _|_ && #config.mastodon.streaming.pdb.maxUnavailable != _|_ {
			maxUnavailable: #config.mastodon.streaming.pdb.maxUnavailable
		}
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "streaming"
		}
	}
}
