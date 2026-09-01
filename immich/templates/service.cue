package templates

#ServiceBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      _config.fullname
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels & {
			"app.kubernetes.io/component": "server"
		}
		if _config.service.annotations != _|_ {
			annotations: _config.service.annotations
		}
	}
	spec: {
		type: _config.service.type
		if _config.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: _config.service.ipFamilyPolicy
		}
		if len(_config.service.ipFamilies) > 0 {
			ipFamilies: _config.service.ipFamilies
		}
		ports: [{
			name:       "http"
			port:       _config.service.port
			targetPort: "http"
		}]
		selector: _config.metadata.labels & {
			"app.kubernetes.io/component": "server"
		}
	}
}
