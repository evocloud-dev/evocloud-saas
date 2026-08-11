package templates

#RouteApi: {
	#config:    #Config
	apiVersion: #config.api.route.main.apiVersion
	kind:       #config.api.route.main.kind
	metadata: {
		name:      "\(#config.metadata.name)-api"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-api"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/version":    #config.moduleVersion
			"app.kubernetes.io/managed-by": "timoni"
		}
		if #config.api.route.main.annotations != _|_ {
			annotations: #config.api.route.main.annotations
		}
	}
	spec: {
		if len(#config.api.route.main.parentRefs) > 0 {
			parentRefs: #config.api.route.main.parentRefs
		}
		if #config.api.route.main.hostnames != _|_ {
			if len(#config.api.route.main.hostnames) > 0 {
				hostnames: #config.api.route.main.hostnames
			}
		}
		rules: [
			{
				matches: #config.api.route.main.matches
				backendRefs: [
					{
						name: "\(#config.metadata.name)-api"
						port: #config.api.service.port
					},
				]
				if #config.api.route.main.filters != _|_ {
					if len(#config.api.route.main.filters) > 0 {
						filters: #config.api.route.main.filters
					}
				}
			},
		]
	}
}
