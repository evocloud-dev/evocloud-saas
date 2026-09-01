package templates

#HTTPRouteBuilder: {
	_config: #Config

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      _config.fullname
		namespace: _config.namespace
		labels:    _config.metadata.labels
	}
	spec: {
		if len(_config.gateway.parentRefs) > 0 {
			parentRefs: _config.gateway.parentRefs
		}
		if len(_config.gateway.hostnames) > 0 {
			hostnames: _config.gateway.hostnames
		}
		rules: [{
			matches: [{
				path: {
					type:  "PathPrefix"
					value: "/"
				}
			}]
			backendRefs: [{
				name: _config.fullname
				port: _config.service.port
			}]
		}]
	}
}
