package templates

#PDBRedis: {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "redis-master-pdb"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		minAvailable: 1
		selector: matchLabels: {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/instance":  "redis"
			"app.kubernetes.io/component": "master"
		}
	}
}
