package templates

// #ExternalSecret mirrors templates/externalsecret.yaml.
#ExternalSecret: {
	#config: #Config
	#index:  int
	#item:   #Config.#ExternalSecretItem

	let _name = [
		if #item.fullnameOverride != "" {#item.fullnameOverride},
		if #item.name != "" {"\(#config.metadata.name)-\(#item.name)"},
		"\(#config.metadata.name)-external-secret-\(#index)",
	][0]

	apiVersion: "external-secrets.io/v1"
	kind:       "ExternalSecret"
	metadata: {
		name:      _name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & #item.labels
		if len(#config.commonAnnotations) > 0 || len(#item.annotations) > 0 {
			annotations: {
				for k, v in #config.commonAnnotations if #item.annotations[k] == _|_ {(k): v}
				#item.annotations
			}
		}
	}
	spec: {
		#item.spec
		if #item.spec.refreshInterval == _|_ && #config.externalSecrets.refreshInterval != "" {
			refreshInterval: #config.externalSecrets.refreshInterval
		}
		if #item.spec.target == _|_ {
			target: name: _name
		}
		if #item.spec.target != _|_ if #item.spec.target.name == _|_ {
			target: name: _name
		}
	}
}
