package templates

#HTTPRoute: {
	#config: #Config
	#route:  #Config.#HTTPRouteItem
	#index:  int

	_routeName: string
	if #route.name != "" {
		_routeName: #route.name
	}
	if #route.name == "" && #index > 0 {
		_routeName: "\(#config._fullname)-\(#index)"
	}
	if #route.name == "" && #index == 0 {
		_routeName: #config._fullname
	}

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      _routeName
		namespace: #config.metadata.namespace
		labels: {
			#config._labels
			if #route.labels != _|_ {
				for k, v in #route.labels {
					"\(k)": v
				}
			}
		}
		if #route.annotations != _|_ {
			annotations: #route.annotations
		}
	}
	spec: {
		parentRefs: [
			for p in #route.parentRefs {
				name: p.name
				if p.group != "" {
					group: p.group
				}
				if p.kind != "" {
					kind: p.kind
				}
				if p.namespace != "" {
					namespace: p.namespace
				}
				if p.sectionName != "" {
					sectionName: p.sectionName
				}
				if p.port != 0 {
					port: p.port
				}
			},
		]
		if len(#route.hostnames) > 0 {
			hostnames: #route.hostnames
		}
		rules: [
			if len(#route.rules) > 0 {
				for r in #route.rules {
					if r.matches != _|_ {
						matches: r.matches
					}
					if r.filters != _|_ {
						filters: r.filters
					}
					let _hasBackendRefs = r.backendRefs != _|_
					backendRefs: [
						if _hasBackendRefs {
							for b in r.backendRefs {b}
						},
						if !_hasBackendRefs && !r.omitDefaultBackend {
							name: #config._fullname
							port: #config.service.port
						},
					]
				}
			},
			if len(#route.rules) == 0 {
				backendRefs: [
					{
						name: #config._fullname
						port: #config.service.port
					},
				]
			},
		]
	}
}

