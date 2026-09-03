package templates

#PDBPhp: {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-php"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		minAvailable: 1
		selector: matchLabels: {
			"app.kubernetes.io/name":     #config.metadata.name
			"app.kubernetes.io/instance": "\(#config.metadata.name)-php"
		}
	}
}
