package templates


#ServiceAccountBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      _config.serviceAccountName
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
		if _config.serviceAccount.annotations != _|_ {
			annotations: _config.serviceAccount.annotations
		}
	}
	automountServiceAccountToken: _config.serviceAccount.automountServiceAccountToken
}
