package templates

#RouteFrontend: {
	#config:    #Config
	apiVersion: #config.frontend.route.main.apiVersion
	kind:       #config.frontend.route.main.kind
	metadata: {
		name:      "\(#config.metadata.name)-frontend"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-frontend"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/version":    #config.moduleVersion
			"app.kubernetes.io/managed-by": "timoni"
		}
		if #config.frontend.route.main.annotations != _|_ {
			annotations: #config.frontend.route.main.annotations
		}
	}
	spec: {
		if len(#config.frontend.route.main.parentRefs) > 0 {
			parentRefs: #config.frontend.route.main.parentRefs
		}
		if #config.frontend.route.main.hostnames != _|_ {
			if len(#config.frontend.route.main.hostnames) > 0 {
				hostnames: #config.frontend.route.main.hostnames
			}
		}
		rules: [
			{
				matches: #config.frontend.route.main.matches
				backendRefs: [
					{
						name: "\(#config.metadata.name)-frontend"
						port: #config.frontend.service.port
					},
				]
				if #config.frontend.route.main.filters != _|_ {
					if len(#config.frontend.route.main.filters) > 0 {
						filters: #config.frontend.route.main.filters
					}
				}
			},
		]
	}
}
