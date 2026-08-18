package templates

#RouteFrontend: {
	#config:      #Config
	#routeName:   string
	#routeConfig: _

	apiVersion: #routeConfig.apiVersion
	kind:       #routeConfig.kind
	metadata: {
		if #routeName == "main" {
			name: "\(#config.metadata.name)-frontend"
		}
		if #routeName != "main" {
			name: "\(#config.metadata.name)-frontend-\(#routeName)"
		}
		namespace: #config.metadata.namespace
		if #routeConfig.annotations != _|_ {
			annotations: #routeConfig.annotations
		}
		labels: {
			#config.metadata.labels
			if #routeConfig.labels != _|_ {
				#routeConfig.labels
			}
		}
	}
	spec: {
		if len(#routeConfig.parentRefs) > 0 {
			parentRefs: #routeConfig.parentRefs
		}
		if len(#routeConfig.hostnames) > 0 {
			hostnames: #routeConfig.hostnames
		}
		rules: [
			if #routeConfig.additionalRules != _|_ for r in #routeConfig.additionalRules {r},
			if #routeConfig.httpsRedirect {
				{
					filters: [
						{
							type: "RequestRedirect"
							requestRedirect: {
								scheme:     "https"
								statusCode: 301
							}
						},
					]
				}
			},
			if !#routeConfig.httpsRedirect {
				{
					backendRefs: [
						{
							name:   "\(#config.metadata.name)-frontend"
							port:   #config.frontend.service.port
							group:  ""
							kind:   "Service"
							weight: 1
						},
					]
					if #routeConfig.filters != _|_ {
						filters: #routeConfig.filters
					}
					if #routeConfig.matches != _|_ {
						matches: #routeConfig.matches
					}
					if #routeConfig.timeouts != _|_ {
						timeouts: #routeConfig.timeouts
					}
				}
			},
		]
	}
}
