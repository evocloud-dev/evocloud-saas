package templates

#HTTPRoute: {
	#config:    #Config
	apiVersion: #config.gatewayAPI.apiVersion
	kind:       "HTTPRoute"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.gatewayAPI.annotations != _|_ {
			annotations: #config.gatewayAPI.annotations
		}
	}
	spec: {
		parentRefs: #config.gatewayAPI.parentRefs
		if len(#config.gatewayAPI.hostnames) > 0 {
			hostnames: #config.gatewayAPI.hostnames
		}
		rules: [
			{
				matches: #config.gatewayAPI.matches
				backendRefs: [
					{
						name: #config.#fullname
						port: #config.service.port
					},
				]
			},
		]
	}
}
