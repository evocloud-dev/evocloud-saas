package templates

// HTTPRoute is part of Gateway API and is not part of the standard core k8s API, 
// so we define it without the core types_gen constraints
#HTTPRoute: {
	#in:    #Config
	apiVersion: #in.httpRoute.apiVersion
	kind:       #in.httpRoute.kind
	metadata:   #in.metadata & {
		if len(#in.httpRoute.annotations) > 0 {
			annotations: #in.httpRoute.annotations
		}
	}
	spec: {
		if len(#in.httpRoute.parentRefs) > 0 {
			parentRefs: #in.httpRoute.parentRefs
		}
		if len(#in.httpRoute.hostnames) > 0 {
			hostnames: #in.httpRoute.hostnames
		}
		rules: [
			if len(#in.httpRoute.rules) > 0 {
				for r in #in.httpRoute.rules {
					{
						backendRefs: [
							{
								name:   #in.metadata.name
								port:   #in.service.port
								weight: 1
							},
						]
						if r.matches != _|_ {
							matches: r.matches
						}
						if r.filters != _|_ {
							filters: r.filters
						}
					}
				}
			},
			if len(#in.httpRoute.rules) == 0 {
				{
					backendRefs: [
						{
							name:   #in.metadata.name
							port:   #in.service.port
							weight: 1
						},
					]
				}
			}
		]
	}
}
