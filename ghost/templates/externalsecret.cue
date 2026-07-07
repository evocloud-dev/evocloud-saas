package templates

#ExternalSecret: {
	#config: #Config

	apiVersion: #config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name:      "\(#config.#serviceName)-db"
		namespace: #config.metadata.namespace
		labels:    #config.labels
	}
	spec: {
		refreshInterval: #config.externalSecrets.refreshInterval
		secretStoreRef: {
			name: #config.externalSecrets.secretStoreRef.name
			kind: #config.externalSecrets.secretStoreRef.kind
		}
		target: {
			name:           #config.database.external.existingSecret
			creationPolicy: #config.externalSecrets.target.creationPolicy
		}
		data: #config.externalSecrets.data
	}
}