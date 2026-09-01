package templates

#DBExternalSecretBuilder: {
	_config: #Config

	apiVersion: _config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name:      _config.database.external.existingSecret
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
			name:           _config.database.external.existingSecret
			creationPolicy: _config.externalSecrets.target.creationPolicy
		}
		if len(_config.externalSecrets.database.data) > 0 {
			data: _config.externalSecrets.database.data
		}
		if len(_config.externalSecrets.database.dataFrom) > 0 {
			dataFrom: _config.externalSecrets.database.dataFrom
		}
	}
}

#RedisExternalSecretBuilder: {
	_config: #Config

	apiVersion: _config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name:      _config.valkey.external.existingSecret
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
			name:           _config.valkey.external.existingSecret
			creationPolicy: _config.externalSecrets.target.creationPolicy
		}
		if len(_config.externalSecrets.redis.data) > 0 {
			data: _config.externalSecrets.redis.data
		}
		if len(_config.externalSecrets.redis.dataFrom) > 0 {
			dataFrom: _config.externalSecrets.redis.dataFrom
		}
	}
}
