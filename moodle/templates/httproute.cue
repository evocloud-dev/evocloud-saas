package templates

#HTTPRoute: {
	#config: #Config
	#route:  _
	#index:  int

	let _routeName = [
		if #route.name != _|_ && #route.name != "" { #route.name },
		#config.#fullname,
	][0]

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      _routeName
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
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
		if #route.parentRefs != _|_ {
			parentRefs: [for p in #route.parentRefs {
				name: p.name
				if p.namespace != _|_ && p.namespace != "" {
					namespace: p.namespace
				}
				if p.group != _|_ && p.group != "" {
					group: p.group
				}
				if p.kind != _|_ && p.kind != "" {
					kind: p.kind
				}
				if p.sectionName != _|_ && p.sectionName != "" {
					sectionName: p.sectionName
				}
				if p.port != _|_ && p.port != 0 {
					port: p.port
				}
			}]
		}
		if #route.hostnames != _|_ && len(#route.hostnames) > 0 {
			hostnames: #route.hostnames
		}
		if #route.rules != _|_ {
			rules: [for r in #route.rules {
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
					backendRefs: [{
						name: #config.#fullname
						port: #config.service.port
					}]
				}
			}]
		}
		if #route.rules == _|_ {
			rules: [{
				backendRefs: [{
					name: #config.#fullname
					port: #config.service.port
				}]
			}]
		}
	}
}

