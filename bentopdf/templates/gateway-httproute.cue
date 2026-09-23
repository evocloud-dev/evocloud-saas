// SPDX-License-Identifier: Apache-2.0

package templates

#HTTPRoute: {
	#config: #Config
	#route:  #HTTPRouteConfig
	#index:  int

	// bentopdf.httpRouteName
	_name: [
		if #route.name != _|_ { #route.name },
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
			parentRefs: #route.parentRefs
		}
		if #route.hostnames != _|_ {
			hostnames: #route.hostnames
		}
		rules: [
			if #route.rules != _|_ {
				for r in #route.rules {
					{
						if r.matches != _|_ {
							matches: r.matches
						}
						if r.filters != _|_ {
							filters: r.filters
						}
						backendRefs: [
							if r.backendRefs != _|_ {
								r.backendRefs
							},
							if r.backendRefs == _|_ && (r.omitDefaultBackend == _|_ || !r.omitDefaultBackend) {
								[{
									name: #config.metadata.name
									port: #config.service.port
								}]
							},
						][0]
					}
				}
			},
			if #route.rules == _|_ {
				{
					backendRefs: [{
						name: #config.metadata.name
						port: #config.service.port
					}]
				}
			},
		]
	}
}

