package templates

#HTTPRoute: {
	#config: #Config

	let routeAnnotations = {
		for k, v in #config.commonAnnotations { "\(k)": v }
		for k, v in #config.gatewayAPI.annotations { "\(k)": v }
	}

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.#labels { "\(k)": v }
			for k, v in #config.gatewayAPI.labels { "\(k)": v }
		}
		if len(routeAnnotations) > 0 {
			annotations: routeAnnotations
		}
	}
	spec: {
		parentRefs: #config.gatewayAPI.parentRefs
		if len(#config.gatewayAPI.hostnames) > 0 {
			hostnames: #config.gatewayAPI.hostnames
		}
		if len(#config.gatewayAPI.rules) > 0 {
			rules: [
				for r in #config.gatewayAPI.rules {
					if r.matches != _|_ && len(r.matches) > 0 {
						matches: r.matches
					}
					if r.filters != _|_ && len(r.filters) > 0 {
						filters: r.filters
					}
					if r.backendRefs != _|_ && len(r.backendRefs) > 0 {
						backendRefs: r.backendRefs
					}
					if (r.backendRefs == _|_ || len(r.backendRefs) == 0) && !r.omitDefaultBackend {
						backendRefs: [{
							name: #config.#fullname
							port: #config.service.port
						}]
					}
				},
			]
		}
		if len(#config.gatewayAPI.rules) == 0 {
			rules: [{
				backendRefs: [{
					name: #config.#fullname
					port: #config.service.port
				}]
			}]
		}
	}
}

#HTTPRouteItemResource: {
	#config: #Config
	#route:  #HTTPRouteItem
	#index:  int

	let routeName = [
		if #route.fullnameOverride != "" { #route.fullnameOverride },
		if #route.name != "" { "\(#config.#fullname)-\(#route.name)" },
		"\(#config.#fullname)-\(#index)",
	][0]

	let routeAnnotations = {
		for k, v in #config.commonAnnotations { "\(k)": v }
		for k, v in #route.annotations { "\(k)": v }
	}

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      routeName
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.#labels { "\(k)": v }
			for k, v in #route.labels { "\(k)": v }
		}
		if len(routeAnnotations) > 0 {
			annotations: routeAnnotations
		}
	}
	spec: {
		parentRefs: #route.parentRefs
		if len(#route.hostnames) > 0 {
			hostnames: #route.hostnames
		}
		if len(#route.rules) > 0 {
			rules: [
				for r in #route.rules {
					if r.matches != _|_ && len(r.matches) > 0 {
						matches: r.matches
					}
					if r.filters != _|_ && len(r.filters) > 0 {
						filters: r.filters
					}
					if r.backendRefs != _|_ && len(r.backendRefs) > 0 {
						backendRefs: r.backendRefs
					}
					if (r.backendRefs == _|_ || len(r.backendRefs) == 0) && !r.omitDefaultBackend {
						backendRefs: [{
							name: #config.#fullname
							port: #config.service.port
						}]
					}
				},
			]
		}
		if len(#route.rules) == 0 {
			rules: [{
				backendRefs: [{
					name: #config.#fullname
					port: #config.service.port
				}]
			}]
		}
	}
}
