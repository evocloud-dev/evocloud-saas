package templates

#DBSecretBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(_config.fullname)-database"
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	type: "Opaque"
	stringData: {
		"database-password": _config.database.external.password
	}
}

#RedisSecretBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(_config.fullname)-redis"
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	type: "Opaque"
	stringData: {
		"redis-password": _config.valkey.external.password
	}
}

#PostgreSQLAuthSecretBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(_config.fullname)-postgresql-auth"
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	type: "Opaque"
	stringData: {
		"postgres-password": _config.postgresql.auth.postgresPassword
		"user-password":     _config.postgresql.auth.password
	}
}

#ValkeyAuthSecretBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(_config.fullname)-valkey-auth"
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	type: "Opaque"
	stringData: {
		"valkey-password": _config.valkey.auth.password
	}
}
