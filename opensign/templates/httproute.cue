package templates

#HTTPRoute: {
	#config: #Config

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      "\(#config.metadata.name)-httproute"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.gateway.annotations) > 0 {
			annotations: #config.gateway.annotations
		}
	}
	spec: {
		if len(#config.gateway.parentRefs) > 0 {
			parentRefs: #config.gateway.parentRefs
		}
		if len(#config.gateway.hostnames) > 0 {
			hostnames: #config.gateway.hostnames
		}
		rules: [
			{
				matches: [{
					path: {
						type:  "PathPrefix"
						value: "/app"
					}
				}]
				backendRefs: [{
					name: "\(#config.metadata.name)-server"
					port: #config.server.port
				}]
			},
			{
				matches: [{
					path: {
						type:  "PathPrefix"
						value: "/"
					}
				}]
				backendRefs: [{
					name: "\(#config.metadata.name)-client"
					port: #config.client.port
				}]
			},
		]
	}
}
