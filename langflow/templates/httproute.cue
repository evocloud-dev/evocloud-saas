// SPDX-License-Identifier: Apache-2.0
package templates

#HTTPRouteBuilder: {
	_config:   #Config
	_fullname: string

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      _fullname
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels & _config.commonLabels
		if _config.gateway.annotations != _|_ {
			annotations: _config.gateway.annotations
		}
	}
	spec: {
		parentRefs: _config.gateway.parentRefs
		if len(_config.gateway.hostnames) > 0 {
			hostnames: _config.gateway.hostnames
		}
		rules: [{
			matches: [{
				path: {
					type:  _config.gateway.pathType
					value: _config.gateway.path
				}
			}]
			backendRefs: [{
				name: _fullname
				port: _config.service.port
			}]
		}]
	}
}
