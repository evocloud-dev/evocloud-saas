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
		if #route.labels != _|_ && len(#route.labels) > 0 {
			labels: #route.labels
		}
		if #route.annotations != _|_ && len(#route.annotations) > 0 {
			annotations: #route.annotations
		}
	}
	spec: {
		if #route.parentRefs != _|_ {
			parentRefs: [
				for p in #route.parentRefs {
					name: p.name
					if p["group"] != _|_ && p["group"] != "" {
						group: p["group"]
					}
					if p["kind"] != _|_ && p["kind"] != "" {
						kind: p["kind"]
					}
					if p["namespace"] != _|_ && p["namespace"] != "" {
						namespace: p["namespace"]
					}
					if p["sectionName"] != _|_ && p["sectionName"] != "" {
						sectionName: p["sectionName"]
					}
					if p["port"] != _|_ && p["port"] > 0 {
						port: p["port"]
					}
				},
			]
		}
		if #route.hostnames != _|_ && len(#route.hostnames) > 0 {
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
