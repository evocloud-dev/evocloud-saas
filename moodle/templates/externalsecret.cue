package templates

#ExternalSecret: {
	#config: #Config
	#item:   _
	#index:  int

	let _esName = [
		if #item.fullnameOverride != _|_ { #item.fullnameOverride },
		if #item.fullnameOverride == _|_ && #item.name != _|_ { "\(#config.#fullname)-\(#item.name)" },
		#config.#secretName,
	][0]

	let _refreshInterval = [
		if #item.spec != _|_ && #item.spec.refreshInterval != _|_ { #item.spec.refreshInterval },
		#config.externalSecrets.refreshInterval,
	][0]

	apiVersion: "external-secrets.io/v1"
	kind:       "ExternalSecret"
	metadata: {
		name:      _esName
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
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
		if #item.spec != _|_ {
			for k, v in #item.spec if k != "refreshInterval" && k != "target" {
				"\(k)": v
			}
		}
		refreshInterval: _refreshInterval
		target: {
			name: _esName
			if #item.spec != _|_ && #item.spec.target != _|_ {
				for k, v in #item.spec.target {
					"\(k)": v
				}
			}
		}
	}
}

