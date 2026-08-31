package templates

#AdminSecretBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(_config.fullname)-admin"
		namespace: _config.namespace
		labels:    _config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		username: _config.admin.username
		password: _config.admin.password
	}
}
