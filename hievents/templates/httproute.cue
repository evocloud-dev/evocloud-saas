package templates

#HTTPRoute: {
	#config: #Config

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      #config._fullname
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels
		if len(#config.httpRoute.annotations) > 0 {
			annotations: #config.httpRoute.annotations
		}
	}
	spec: {
		if len(#config.httpRoute.parentRefs) > 0 {
			parentRefs: #config.httpRoute.parentRefs
		}
		if len(#config.httpRoute.hostnames) > 0 {
			hostnames: #config.httpRoute.hostnames
		}
		rules: [{
			matches: [{
				path: {
					type:  "PathPrefix"
					value: #config.httpRoute.rules.apiPrefix
				}
			}, {
				path: {
					type:  "PathPrefix"
					value: "/storage"
				}
			}]
			backendRefs: [{
				name: #config._backendName
				port: #config.backend.service.port
			}]
		}, {
			backendRefs: [{
				name: #config._frontendName
				port: #config.frontend.service.port
			}]
		}]
	}
}
