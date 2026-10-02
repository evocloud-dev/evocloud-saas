package templates

#HTTPRoute: {
	#config: #Config
	#route:  _
	#index:  int

	_routeName: [
		if #route.name != _|_ && #route.name != "" {#route.name},
		if #index > 0 {"\(#config.metadata.name)-\(#index)"},
		#config.metadata.name,
	][0]

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      _routeName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #route.labels != _|_ {
			labels: #route.labels
		}
		if #route.annotations != _|_ {
			annotations: #route.annotations
		}
	}
	spec: {
		if #route.parentRefs != _|_ {
			parentRefs: #route.parentRefs
		}
		if #route.hostnames != _|_ {
			hostnames: #route.hostnames
		}
		if #route.rules != _|_ {
			rules: [
				for r in #route.rules {
					let _omit = [if r["omitDefaultBackend"] != _|_ {r["omitDefaultBackend"]}, false][0]
					if r.matches != _|_ {
						matches: r.matches
					}
					if r.filters != _|_ {
						filters: r.filters
					}
					if r.backendRefs != _|_ {
						backendRefs: r.backendRefs
					}
					if r.backendRefs == _|_ && !_omit {
						backendRefs: [
							{
								name: #config.metadata.name
								port: #config.service.port
							},
						]
					}
				},
			]
		}
		if #route.rules == _|_ {
			rules: [
				{
					backendRefs: [
						{
							name: #config.metadata.name
							port: #config.service.port
						},
					]
				},
			]
		}
	}
}
