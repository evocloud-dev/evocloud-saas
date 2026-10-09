package templates

#HTTPRoute: {
	#config: #Config

	apiVersion: #config.gateway.apiVersion
	kind:       "HTTPRoute"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels:    #config.#labels
		if #config.gateway.annotations != _|_ {
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
			for r in #config.gateway.rules {
				matches: r.matches
				backendRefs: [
					{
						name: #config.#proxyServiceName
						port: #config.service.port
					},
				]
			},
		]
	}
}
