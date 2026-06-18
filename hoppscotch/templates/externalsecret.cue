package templates

#ExternalSecret: {
	#config: #Config
	apiVersion: #config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name:      #config.fullname
		namespace: #config.namespace
		labels:    #config.labels
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
			name:           #config.fullname
			creationPolicy: "Owner"
		}
		if #config.externalSecrets.data != _|_ && len(#config.externalSecrets.data) > 0 {
			data: #config.externalSecrets.data
		}
		if #config.externalSecrets.dataFrom != _|_ && len(#config.externalSecrets.dataFrom) > 0 {
			dataFrom: #config.externalSecrets.dataFrom
		}
	}
}
