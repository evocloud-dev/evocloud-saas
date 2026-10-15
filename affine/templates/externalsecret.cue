package templates

#ExternalSecret: {
	#config: #Config
	#item:   #Config.#ExternalSecretItem

	_extName: string
	if #item.fullnameOverride != _|_ && #item.fullnameOverride != "" {
		_extName: #item.fullnameOverride
	}
	if (#item.fullnameOverride == _|_ || #item.fullnameOverride == "") && #item.name != _|_ && #item.name != "" {
		_extName: "\(#config._fullname)-\(#item.name)"
	}
	if (#item.fullnameOverride == _|_ || #item.fullnameOverride == "") && (#item.name == _|_ || #item.name == "") {
		_extName: "\(#config._fullname)-bootstrap"
	}

	apiVersion: "external-secrets.io/v1"
	kind:       "ExternalSecret"
	metadata: {
		name:      _extName
		namespace: #config.metadata.namespace
		labels: {
			#config._labels
			if #item.labels != _|_ {
				for k, v in #item.labels {
					"\(k)": v
				}
			}
		}
		if #item.annotations != _|_ {
			annotations: #item.annotations
		}
	}
	spec: {
		for k, v in #item.spec {
			"\(k)": v
		}
		refreshInterval: string | *#config.externalSecrets.refreshInterval
		if #item.spec.refreshInterval != _|_ {
			refreshInterval: #item.spec.refreshInterval
		}
		target: {
			if #item.spec.target != _|_ {
				for k, v in #item.spec.target {
					"\(k)": v
				}
			}
			name: string | *_extName
			if #item.spec.target != _|_ && #item.spec.target.name != _|_ {
				name: #item.spec.target.name
			}
		}
	}
}

