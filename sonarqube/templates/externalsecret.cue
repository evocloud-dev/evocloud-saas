package templates



#ExternalSecretDB: {
	#config:    #Config
	apiVersion: #config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name:      "\(#config.fullname)-database"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "sonarqube"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		refreshInterval: #config.externalSecrets.refreshInterval
		secretStoreRef: {
			name: #config.externalSecrets.secretStoreRef.name
			kind: #config.externalSecrets.secretStoreRef.kind
		}
		target: {
			name:           #config.databaseSecretName
			creationPolicy: #config.externalSecrets.target.creationPolicy
		}
		data: [
			{
				secretKey: #config.databaseSecretKey
				remoteRef: {
					key: #config.externalSecrets.database.passwordRemoteRef.key
					if #config.externalSecrets.database.passwordRemoteRef.property != _|_ {
						property: #config.externalSecrets.database.passwordRemoteRef.property
					}
					if #config.externalSecrets.database.passwordRemoteRef.version != _|_ {
						version: #config.externalSecrets.database.passwordRemoteRef.version
					}
					if #config.externalSecrets.database.passwordRemoteRef.decodingStrategy != _|_ {
						decodingStrategy: #config.externalSecrets.database.passwordRemoteRef.decodingStrategy
					}
					if #config.externalSecrets.database.passwordRemoteRef.conversionStrategy != _|_ {
						conversionStrategy: #config.externalSecrets.database.passwordRemoteRef.conversionStrategy
					}
				}
			},
		]
	}
}

#ExternalSecretMonitoring: {
	#config:    #Config
	apiVersion: #config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name:      "\(#config.fullname)-monitoring"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "sonarqube"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		refreshInterval: #config.externalSecrets.refreshInterval
		secretStoreRef: {
			name: #config.externalSecrets.secretStoreRef.name
			kind: #config.externalSecrets.secretStoreRef.kind
		}
		target: {
			name:           #config.monitoringSecretName
			creationPolicy: #config.externalSecrets.target.creationPolicy
		}
		data: [
			{
				secretKey: #config.monitoringSecretKey
				remoteRef: {
					key: #config.externalSecrets.monitoringPasscode.remoteRef.key
					if #config.externalSecrets.monitoringPasscode.remoteRef.property != _|_ {
						property: #config.externalSecrets.monitoringPasscode.remoteRef.property
					}
					if #config.externalSecrets.monitoringPasscode.remoteRef.version != _|_ {
						version: #config.externalSecrets.monitoringPasscode.remoteRef.version
					}
					if #config.externalSecrets.monitoringPasscode.remoteRef.decodingStrategy != _|_ {
						decodingStrategy: #config.externalSecrets.monitoringPasscode.remoteRef.decodingStrategy
					}
					if #config.externalSecrets.monitoringPasscode.remoteRef.conversionStrategy != _|_ {
						conversionStrategy: #config.externalSecrets.monitoringPasscode.remoteRef.conversionStrategy
					}
				}
			},
		]
	}
}
