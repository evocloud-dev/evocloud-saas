// SPDX-License-Identifier: Apache-2.0
package templates

#SecretBuilder: {
	_config:         #Config
	_authSecretName: string

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      _authSecretName
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	type: "Opaque"
	stringData: {
		"\(_config.auth.secretKeyKey)":         _config.auth.secretKey
		"\(_config.auth.superuserKey)":         _config.auth.superuser
		"\(_config.auth.superuserPasswordKey)": _config.auth.superuserPassword
	}
}

#DatabaseSecretBuilder: {
	_config:       #Config
	_dbSecretName: string

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      _dbSecretName
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	type: "Opaque"
	stringData: {
		"\(_config.database.urlKey)": _config.database.url
	}
}
