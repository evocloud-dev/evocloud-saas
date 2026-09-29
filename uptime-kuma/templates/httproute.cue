package templates

#HTTPRoute: {
	#config: #Config
	#route: {...}
	#index: int

	let _routeName = [
		if #route.name != _|_ {#route.name},
		"",
	][0]

	let _name = [
		if _routeName != "" {"\(#config._name)-\(_routeName)"},
		#config._name,
	][0]

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      _name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #route.labels != _|_ && len(#route.labels) > 0 {
			labels: #route.labels
		}
		if #route.annotations != _|_ && len(#route.annotations) > 0 {
			annotations: #route.annotations
		}
	}
	spec: {
		if #route.parentRefs != _|_ && len(#route.parentRefs) > 0 {
			parentRefs: #route.parentRefs
		}
		if #route.hostnames != _|_ && len(#route.hostnames) > 0 {
			hostnames: #route.hostnames
		}
		if #route.rules != _|_ {
			rules: [
				for r in #route.rules {
					{
						if r.matches != _|_ {
							matches: r.matches
						}
						if r.filters != _|_ {
							filters: r.filters
						}
						if r.backendRefs != _|_ {
							backendRefs: r.backendRefs
						}
						if r.backendRefs == _|_ {
							let _omit = [if r.omitDefaultBackend != _|_ {r.omitDefaultBackend}, false][0]
							if !_omit {
								backendRefs: [{
									name: #config._name
									port: #config.service.port
								}]
							}
						}
					}
				},
			]
		}
		if #route.rules == _|_ {
			rules: [{
				backendRefs: [{
					name: #config._name
					port: #config.service.port
				}]
			}]
		}
	}
}
