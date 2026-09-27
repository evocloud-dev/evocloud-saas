package templates

#HTTPRoute: {
	#config: #Config
	#route:  _
	#index:  int

	_name: [
		if #route.name != _|_ && #route.name != "" {#route.name},
		if #index > 0 {"\(#config.metadata.name)-\(#index)"},
		#config.metadata.name,
	][0]

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      _name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #route.labels != _|_ {
			for k, v in #route.labels {
				labels: (k): v
			}
		}
		annotations: {
			if #config.metadata.annotations != _|_ {
				for k, v in #config.metadata.annotations {
					(k): v
				}
			}
			if #route.annotations != _|_ {
				for k, v in #route.annotations {
					annotations: (k): v
				}
			}
		}
	}
	spec: {
		if #route.parentRefs != _|_ {
			parentRefs: [
				for ref in #route.parentRefs {
					let _p = {
						name:         string
						group?:       string
						kind?:        string
						namespace?:   string
						sectionName?: string
						port?:        int
						ref
					}
					name: _p.name
					if _p.group != _|_ && _p.group != "" {
						group: _p.group
					}
					if _p.kind != _|_ && _p.kind != "" {
						kind: _p.kind
					}
					if _p.namespace != _|_ && _p.namespace != "" {
						namespace: _p.namespace
					}
					if _p.sectionName != _|_ && _p.sectionName != "" {
						sectionName: _p.sectionName
					}
					if _p.port != _|_ && _p.port > 0 {
						port: _p.port
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
					let _rule = {omitDefaultBackend: false, r}
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
						if r.backendRefs == _|_ && !_rule.omitDefaultBackend {
							backendRefs: [{
								name: #config.metadata.name
								port: #config.service.port
							}]
						}
					}
				},
			]
		}
		if #route.rules == _|_ {
			rules: [{
				backendRefs: [{
					name: #config.metadata.name
					port: #config.service.port
				}]
			}]
		}
	}
}

