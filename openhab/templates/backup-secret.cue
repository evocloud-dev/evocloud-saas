package templates

#BackupSecretBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(_config.fullname)-backup"
		namespace: _config.namespace
		labels:    _config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"access-key": _config.backup.s3.accessKey
		"secret-key": _config.backup.s3.secretKey
	}
}
