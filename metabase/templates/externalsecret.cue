package templates

#ExternalSecret: {
	#config: #Config
	apiVersion: #config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name:      #config.metabase.existingSecret
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		refreshInterval: #config.externalSecrets.refreshInterval
		secretStoreRef: {
			name: #config.externalSecrets.secretStoreRef.name
			kind: #config.externalSecrets.secretStoreRef.kind
		}
		target: {
			name:           #config.metabase.existingSecret
			creationPolicy: #config.externalSecrets.target.creationPolicy
		}
		if #config.externalSecrets.data != _|_ {
			data: #config.externalSecrets.data
		}
	}
}
