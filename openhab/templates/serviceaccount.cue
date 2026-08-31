package templates

#ServiceAccountBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      _config.serviceAccountName
		namespace: _config.namespace
		labels:    _config.selector.labels
		if len(_config.serviceAccount.annotations) > 0 {
			annotations: _config.serviceAccount.annotations
		}
	}
	automountServiceAccountToken: _config.serviceAccount.automountServiceAccountToken
}
