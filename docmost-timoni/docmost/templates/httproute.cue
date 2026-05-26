package templates

#HTTPRoute: {
	#config:    #Config
	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.gateway.annotations != _|_ {
			annotations: #config.gateway.annotations
		}
	}
	spec: {
		parentRefs: [
			for p in #config.gateway.parentRefs {
				name: p.name
				if p.namespace != _|_ {
					namespace: p.namespace
				}
				if p.kind != _|_ {
					kind: p.kind
				}
				if p.group != _|_ {
					group: p.group
				}
			}
		]
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
				name: #config.metadata.name
				port: #config.service.port
			}]
		}]
	}
}
