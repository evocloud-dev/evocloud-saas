package templates

#ExternalSecret: {
	#config: #Config
	apiVersion: #config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name: [
			if #config.externalSecrets.name != "" {#config.externalSecrets.name},
			if #config.existingSecret != "" {#config.existingSecret},
			"\(#config.metadata.name)-env",
		][0]
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.externalSecrets.annotations != _|_ && len(#config.externalSecrets.annotations) > 0 {
			annotations: #config.externalSecrets.annotations
		}
	}
	spec: {
		refreshInterval: #config.externalSecrets.refreshInterval
		secretStoreRef: {
			name: #config.externalSecrets.secretStoreRef.name
			kind: #config.externalSecrets.secretStoreRef.kind
		}
		target: {
			name: [
				if #config.externalSecrets.target.name != "" {#config.externalSecrets.target.name},
				if #config.existingSecret != "" {#config.existingSecret},
				"\(#config.metadata.name)-env",
			][0]
			creationPolicy: #config.externalSecrets.target.creationPolicy
			if #config.externalSecrets.target.template != _|_ {
				template: #config.externalSecrets.target.template
			}
		}
		if #config.externalSecrets.data != _|_ && len(#config.externalSecrets.data) > 0 {
			data: #config.externalSecrets.data
		}
		if #config.externalSecrets.dataFrom != _|_ && len(#config.externalSecrets.dataFrom) > 0 {
			dataFrom: #config.externalSecrets.dataFrom
		}
	}
}
