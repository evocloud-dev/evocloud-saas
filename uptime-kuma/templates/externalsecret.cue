package templates

#ExternalSecret: {
	#config: #Config
	#item: {...}
	#index: int

	let _itemName = [
		if #item.name != _|_ {#item.name},
		"external",
	][0]

	let _name = "\(#config._name)-\(_itemName)"

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
		refreshInterval: [
			if #item.spec != _|_ if #item.spec.refreshInterval != _|_ {#item.spec.refreshInterval},
			#config.externalSecrets.refreshInterval,
		][0]

		target: {
			name: [
				if #item.spec != _|_ if #item.spec.target != _|_ if #item.spec.target.name != _|_ {#item.spec.target.name},
				_name,
			][0]
			if #item.spec != _|_ if #item.spec.target != _|_ {
				for k, v in #item.spec.target {
					if k != "name" {
						"\(k)": v
					}
				}
			}
		}

		if #item.spec != _|_ {
			for k, v in #item.spec {
				if k != "refreshInterval" && k != "target" {
					"\(k)": v
				}
			}
		}
	}
}
