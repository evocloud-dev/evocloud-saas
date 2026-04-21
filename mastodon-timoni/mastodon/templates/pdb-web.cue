package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PdbWeb: policyv1.#PodDisruptionBudget & {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		namespace: #config.#namespace
		name:   "\(#config.metadata.name)-web"
		labels: #config.metadata.labels
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		if #config.mastodon.web.pdb.minAvailable != _|_ {
			minAvailable: #config.mastodon.web.pdb.minAvailable
		}
		if #config.mastodon.web.pdb.minAvailable == _|_ && #config.mastodon.web.pdb.maxUnavailable != _|_ {
			maxUnavailable: #config.mastodon.web.pdb.maxUnavailable
		}
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "web"
			"app.kubernetes.io/part-of":   "rails"
		}
	}
}
