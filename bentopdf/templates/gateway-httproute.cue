// SPDX-License-Identifier: Apache-2.0

package templates

#HTTPRoute: {
	#config: #Config
	#route:  #HTTPRouteConfig
	#index:  int

	// bentopdf.httpRouteName
	let _nameOverride = [if #route.name != _|_ { #route.name }, ""][0]
	_name: [
		if _nameOverride != "" { _nameOverride },
		if #index > 0 { "\(#config.metadata.name)-\(#index)" },
		#config.metadata.name,
	][0]

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      _name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			if #route.labels != _|_ { #route.labels }
		}
		if #route.annotations != _|_ {
			annotations: #route.annotations
		}
	}
	spec: {
		if #route.parentRefs != _|_ {
			parentRefs: [
				for p in #route.parentRefs {
					name: p.name
					let _ns = [if p.namespace != _|_ { p.namespace }, ""][0]
					if _ns != "" {
						namespace: _ns
					}
					let _grp = [if p.group != _|_ { p.group }, ""][0]
					if _grp != "" {
						group: _grp
					}
					let _knd = [if p.kind != _|_ { p.kind }, ""][0]
					if _knd != "" {
						kind: _knd
					}
					let _sec = [if p.sectionName != _|_ { p.sectionName }, ""][0]
					if _sec != "" {
						sectionName: _sec
					}
					if p.port != _|_ {
						port: p.port
					}
				},
			]
		}
		let _hasHostnames = [if #route.hostnames != _|_ { true }, false][0]
		if _hasHostnames && len(#route.hostnames) > 0 {
			hostnames: #route.hostnames
		}
		let _hasRules = [if #route.rules != _|_ { true }, false][0]
		if _hasRules && len(#route.rules) > 0 {
			rules: [
				for r in #route.rules {
					let _hasBackends = [if r.backendRefs != _|_ { true }, false][0]
					let _omit = [if r.omitDefaultBackend != _|_ { r.omitDefaultBackend }, false][0]
					{
						if r.matches != _|_ {
							matches: r.matches
						}
						if r.filters != _|_ {
							filters: r.filters
						}
						if _hasBackends {
							backendRefs: r.backendRefs
						}
						if !_hasBackends && !_omit {
							backendRefs: [{
								name: #config.metadata.name
								port: #config.service.port
							}]
						}
					}
				},
			]
		}
		if !_hasRules || len(#route.rules) == 0 {
			rules: [
				{
					backendRefs: [{
						name: #config.metadata.name
						port: #config.service.port
					}]
				},
			]
		}
	}
}
