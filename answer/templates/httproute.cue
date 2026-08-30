package templates

#HTTPRoute: {
	#config: #Config

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      #config.fullname
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
		rules: [{
			matches: [{
				path: {
					type:  #config.gateway.pathType
					value: #config.gateway.path
				}
			}]
			backendRefs: [{
				name: #config.fullname
				port: #config.service.port
			}]
		}]
	}
}
