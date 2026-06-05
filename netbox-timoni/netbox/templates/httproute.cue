package templates

#HTTPRoute: {
	#config: #Config

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      #config._fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.commonAnnotations != _|_ || #config.httpRoute.annotations != _|_ {
			annotations: {
				for k, v in #config.httpRoute.annotations {
					"\(k)": v
				}
				for k, v in #config.commonAnnotations {
					"\(k)": v
				}
			}
		}
	}
	spec: {
		if #config.httpRoute.parentRefs != _|_ {
			parentRefs: #config.httpRoute.parentRefs
		}
		if #config.httpRoute.hostnames != _|_ {
			hostnames: #config.httpRoute.hostnames
		}
		rules: [
			{
				matches: [{
					path: {
						type:  "PathPrefix"
						value: "/"
					}
				}]
				if #config.httpRoute.filters != _|_ {
					filters: #config.httpRoute.filters
				}
				backendRefs: [{
					name: #config._fullname
					port: #config.service.port
				}]
			},
		]
	}
}
