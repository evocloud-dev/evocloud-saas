package templates

#HTTPRouteBuilder: {
	_config: #Config

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      _config.fullname
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
		if len(_config.gateway.annotations) > 0 {
			annotations: _config.gateway.annotations
		}
	}
	spec: {
		parentRefs: [
			for pr in _config.gateway.parentRefs {
				name: pr.name
				if pr.namespace != _|_ {namespace: pr.namespace}
				if pr.group != _|_ {group: pr.group}
				if pr.kind != _|_ {kind: pr.kind}
				if pr.sectionName != _|_ {sectionName: pr.sectionName}
				if pr.port != _|_ {port: pr.port}
			},
		]
		if len(_config.gateway.hostnames) > 0 {
			hostnames: _config.gateway.hostnames
		}
		rules: [
			{
				matches: [{
					path: {
						type:  _config.gateway.pathType
						value: _config.gateway.path
					}
				}]
				backendRefs: [{
					name: _config.fullname
					port: _config.service.port
				}]
			},
		]
	}
}
