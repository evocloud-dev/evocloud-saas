package templates

#ExternalSecretAdmin: {
	#config: #Config

	apiVersion: #config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name:      #config.admin.existingSecret
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
			name:           #config.admin.existingSecret
			creationPolicy: #config.externalSecrets.target.creationPolicy
		}
		data: #config.externalSecrets.admin.data
	}
}

#ExternalSecretDatabase: {
	#config: #Config

	apiVersion: #config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name:      #config.database.external.existingSecret
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
		data: #config.externalSecrets.database.data
	}
}

#ExternalSecretBackup: {
	#config: #Config

	apiVersion: #config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name:      #config.backup.s3.existingSecret
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
			name:           #config.backup.s3.existingSecret
			creationPolicy: #config.externalSecrets.target.creationPolicy
		}
		data: #config.externalSecrets.backup.data
	}
}
