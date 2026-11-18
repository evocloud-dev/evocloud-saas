package templates

#ExternalSecret: {
	#config: #Config
	#item:   _
	#index:  *0 | int

	_name: string
	if #item.fullnameOverride != _|_ {
		_name: #item.fullnameOverride
	}
	if #item.fullnameOverride == _|_ && #item.name != _|_ {
		_name: "\(#config.#fullname)-\(#item.name)"
	}
	if #item.fullnameOverride == _|_ && #item.name == _|_ && #index > 0 {
		_name: "\(#config.#fullname)-\(#index)"
	}
	if #item.fullnameOverride == _|_ && #item.name == _|_ && #index == 0 {
		_name: #config.#secretName
	}

	apiVersion: #config.externalSecrets.apiVersion
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
	spec: {
		#item.spec
		if #item.spec.refreshInterval == _|_ {
			refreshInterval: #config.externalSecrets.refreshInterval
		}
		if #item.spec.target == _|_ || #item.spec.target.name == _|_ {
			target: name: _name
		}
	}
}
