package templates

#ExternalSecret: {
	#config: #Config
	#item:   _

	_defaultName: [
		if #item.name != _|_ {#item.name},
		"auth",
	][0]
	_name: [
		if #item.fullnameOverride != _|_ {#item.fullnameOverride},
		"\(#config.metadata.name)-\(_defaultName)",
	][0]

	apiVersion: "external-secrets.io/v1"
	kind:       "ExternalSecret"
	metadata: {
		name:      _name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #item.labels != _|_ {
			for k, v in #item.labels {
				labels: (k): v
			}
		}
		annotations: {
			if #config.metadata.annotations != _|_ {
				for k, v in #config.metadata.annotations {
					(k): v
				}
			}
			if #item.annotations != _|_ {
				for k, v in #item.annotations {
					annotations: (k): v
				}
			}
		}
	}
	spec: {
		#item.spec

		if #item.spec.refreshInterval == _|_ {
			refreshInterval: #config.externalSecrets.refreshInterval
		}
		target: {
			if #item.spec.target != _|_ {
				#item.spec.target
			}
			if #item.spec.target == _|_ || #item.spec.target.name == _|_ {
				name: _name
			}
		}
	}
}

