package templates

#PDBBuilder: {
	_config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      _config.fullname
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	spec: {
		minAvailable: _config.pdb.minAvailable
		selector: matchLabels: _config.metadata.labels & {
			"app.kubernetes.io/component": "server"
		}
	}
}
