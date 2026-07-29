package templates

#ServerHTTPRoute: {
	#config:    #Config
	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      *"\((#config.metadata.name))-server" | string
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.server.httpRoute.annotations != _|_ {
			annotations: #config.server.httpRoute.annotations
		}
	}
	spec: {
		if #config.server.httpRoute.parentRefs != _|_ {
			parentRefs: #config.server.httpRoute.parentRefs
		}
		if len(#config.server.httpRoute.hostnames) > 0 {
			hostnames: #config.server.httpRoute.hostnames
		}
		rules: [
			{
				if #config.server.httpRoute.matches != _|_ {
					matches: #config.server.httpRoute.matches
				}
				if #config.server.httpRoute.filters != _|_ {
					filters: #config.server.httpRoute.filters
				}
				backendRefs: [
					{
						name: *"\((#config.metadata.name))-svc" | string
						port: #config.server.service.port
					}
				]
			},
			if #config.server.httpRoute.extraRules != _|_ {
				for er in #config.server.httpRoute.extraRules {er}
			},
		]
	}
}
