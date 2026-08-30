package templates

#ExternalSecret: {
	#config: #Config
	#item:   _
	apiVersion: "external-secrets.io/v1"
	kind:       "ExternalSecret"
	metadata: {
		name: [
			if #item.name != _|_ && #item.name != "" {"\(#config.fullname)-\(#item.name)"},
			#config.fullname,
		][0]
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		refreshInterval: [if #item.refreshInterval != _|_ {#item.refreshInterval}, "1h"][0]
		secretStoreRef:  #item.storeRef
		target: name: [
			if #item.targetName != _|_ && #item.targetName != "" {#item.targetName},
			if #item.name != _|_ && #item.name != "" {"\(#config.fullname)-\(#item.name)"},
			#config.fullname,
		][0]
		data: #item.data
	}
}
