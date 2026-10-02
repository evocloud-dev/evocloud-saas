package templates

#ExternalSecret: {
	#config: #Config
	#item:   _

	_name: [
		if #item.fullnameOverride != _|_ && #item.fullnameOverride != "" {#item.fullnameOverride},
		if #item.name != _|_ && #item.name != "" {"\(#config.metadata.name)-\(#item.name)"},
		"\(#config.metadata.name)-bootstrap",
	][0]

	apiVersion: "external-secrets.io/v1"
	kind:       "ExternalSecret"
	metadata: {
		name:      _name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #item.labels != _|_ {
			labels: #item.labels
		}
		if #item.annotations != _|_ {
			annotations: #item.annotations
		}
	}
	spec: #item.spec & {
		if #item.spec.refreshInterval == _|_ {
			refreshInterval: #config.externalSecrets.refreshInterval
		}
		if #item.spec.target == _|_ || #item.spec.target.name == _|_ {
			target: name: _name
		}
	}
}

