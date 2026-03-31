package templates

#HTTPRoute: {
	#config: #Config
	#name:   string
	#route:  #config.route[#name]

	apiVersion: #route.apiVersion
	kind:       #route.kind
	metadata: {
		name:      #config.metadata.name + "-" + #name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	if #route.annotations != _|_ {
		metadata: annotations: #route.annotations
	}
	if #route.labels != _|_ {
		metadata: labels: #route.labels
	}

	spec: {
		if #route.parentRefs != _|_ {
			parentRefs: #route.parentRefs
		}
		if #route.hostnames != _|_ {
			hostnames: #route.hostnames
		}
		rules: [
			if #route.httpsRedirect {
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
			{
				backendRefs: [
					{
						name: #config.metadata.name
						port: #config.service.port
						group: ""
						kind:  "Service"
						weight: 1
					},
				]
				if #route.filters != _|_ {
					filters: #route.filters
				}
				if #route.matches != _|_ {
					matches: #route.matches
				}
			},
		]
	}
}
