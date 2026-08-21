package templates

#HTTPRoute: {
	#config: #Config
	apiVersion: #config.gatewayAPI.apiVersion
	kind:       "HTTPRoute"
	metadata: {
		name:        #config.fullname
		namespace:   #config.metadata.namespace
		labels:      #config.metadata.labels
		annotations: #config.gatewayAPI.annotations
	}
	spec: {
		if len(#config.gatewayAPI.parentRefs) > 0 {
			parentRefs: #config.gatewayAPI.parentRefs
		}
		if len(#config.gatewayAPI.hostnames) > 0 {
			hostnames: #config.gatewayAPI.hostnames
		}
		rules: [
			{
				if len(#config.gatewayAPI.matches) > 0 {
					matches: #config.gatewayAPI.matches
				}
				backendRefs: [
					{
						name: #config.fullname
						port: #config.service.port
					},
				]
			},
		]
	}
}
