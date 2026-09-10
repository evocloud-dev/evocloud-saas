package templates

#ExternalSecretBuilder: {
	_config: #Config

	apiVersion: _config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name:      _config.encryptionKey.existingSecret
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	spec: {
		refreshInterval: _config.externalSecrets.refreshInterval
		secretStoreRef: {
			name: _config.externalSecrets.secretStoreRef.name
			kind: _config.externalSecrets.secretStoreRef.kind
		}
		target: {
			name:           _config.encryptionKey.existingSecret
			creationPolicy: _config.externalSecrets.target.creationPolicy
		}
		data: [
			for d in _config.externalSecrets.data {
				secretKey: d.secretKey
				remoteRef: {
					key: d.remoteRef.key
					if d.remoteRef.property != _|_ {property: d.remoteRef.property}
				}
			},
		]
	}
}
