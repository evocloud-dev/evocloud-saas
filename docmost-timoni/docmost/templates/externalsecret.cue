package templates

#ExternalSecret: {
	#config: #Config
	apiVersion: #config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name:      "\(#config.metadata.name)-database"
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
			name:           #config.database.external.existingSecret
			creationPolicy: #config.externalSecrets.target.creationPolicy
		}
		data: [
			for d in #config.externalSecrets.data {
				secretKey: d.secretKey
				remoteRef: {
					key:      d.remoteRef.key
					property: d.remoteRef.property
				}
			},
		]
	}
}
