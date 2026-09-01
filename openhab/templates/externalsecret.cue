package templates

#ExternalSecretBuilder: {
	_config: #Config

	apiVersion: _config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name:      "\(_config.fullname)-credentials"
		namespace: _config.namespace
		labels:    _config.metadata.labels
	}
	spec: {
		refreshInterval: _config.externalSecrets.refreshInterval
		secretStoreRef:  _config.externalSecrets.secretStoreRef
		target: {
			if _config.admin.existingSecret != "" {
				name: _config.admin.existingSecret
			}
			creationPolicy: _config.externalSecrets.target.creationPolicy
		}
		if len(_config.externalSecrets.data) > 0 {
			data: _config.externalSecrets.data
		}
	}
}
