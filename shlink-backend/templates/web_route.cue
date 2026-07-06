package templates

#WebHTTPRoute: {
	#config:    #Config
	#routeName: string
	#route:     #config.web.route[#routeName]

	apiVersion: #route.apiVersion
	kind:       #route.kind
	metadata: {
		name: "\(#config.metadata.name)-web"
		if #routeName != "main" {
			name: "\(#config.metadata.name)-web-\(#routeName)"
		}
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels
		if len(#route.annotations) > 0 {
			annotations: #route.annotations
		}
		if len(#route.labels) > 0 {
			labels: #config.metadata.labels & #route.labels
		}
	}
	spec: {
		if len(#route.parentRefs) > 0 {
			parentRefs: #route.parentRefs
		}
		if len(#route.hostnames) > 0 {
			hostnames: #route.hostnames
		}
		rules: [
			for rule in #route.additionalRules {rule},
			if #route.httpsRedirect {
				{
					filters: [{
						type: "RequestRedirect"
						requestRedirect: {
							scheme:     "https"
							statusCode: 301
						}
					}]
				}
			},
			if !#route.httpsRedirect {
				{
					backendRefs: [{
						name:   "\(#config.metadata.name)-web"
						port:   #config.web.service.port
						group:  ""
						kind:   "Service"
						weight: 1
					}]
					if len(#route.filters) > 0 {
						filters: #route.filters
					}
					if len(#route.matches) > 0 {
						matches: #route.matches
					}
					if len(#route.timeouts) > 0 {
						timeouts: #route.timeouts
					}
				}
			},
		]
	}
}
