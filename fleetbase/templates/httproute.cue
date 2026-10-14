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
						backendRefs: [
							for b in r.backendRefs {
								let _svcName = [
									if b.name == "httpd" || b.name == "fleetbase-httpd" || b.name == "\(#config.metadata.name)-httpd" {"\(#config.metadata.name)-httpd"},
									if b.name == "socket" || b.name == "fleetbase-socket" || b.name == "\(#config.metadata.name)-socket" {"\(#config.metadata.name)-socket"},
									if b.name == "console" || b.name == "fleetbase-console" || b.name == "\(#config.metadata.name)-console" {"\(#config.metadata.name)-console"},
									if b.name == "application" || b.name == "fleetbase-application" || b.name == "\(#config.metadata.name)-application" {"\(#config.metadata.name)-application"},
									b.name,
								][0]
								name: _svcName
								port: b.port
								if b["weight"] != _|_ {
									weight: b["weight"]
								}
								if b["group"] != _|_ {
									group: b["group"]
								}
								if b["kind"] != _|_ {
									kind: b["kind"]
								}
								if b["namespace"] != _|_ {
									namespace: b["namespace"]
								}
							},
						]
					}
					if r.backendRefs == _|_ && !_omit {
						backendRefs: [
							{
								name: "\(#config.metadata.name)-console"
								port: #config.console.port
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
							name: "\(#config.metadata.name)-console"
							port: #config.console.port
						},
					]
				},
			]
		}
	}
}
