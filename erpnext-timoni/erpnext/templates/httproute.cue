package templates

#HTTPRoute: {
	#config: #Config

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		if #config.httproute.name != "" {
			name: #config.httproute.name
		}
		if #config.httproute.name == "" {
			name: "\(#config.metadata.name)-httproute"
		}
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		parentRefs: [
			for p in #config.httproute.parentRefs {
				name:      p.gatewayName
				if p.gatewayNamespace != _|_ && p.gatewayNamespace != "" {
					namespace: p.gatewayNamespace
				}
				if p.gatewaySectionName != _|_ {
					sectionName: p.gatewaySectionName
				}
			},
		]
		hostnames: #config.httproute.hostnames
		rules: [
			for r in #config.httproute.rules {
				matches: [
					for m in r.matches {
						path: {
							type:  m.pathType
							value: m.path
						}
					},
				]
				backendRefs: [
					{
						name: #config.metadata.name
						port: #config.nginx.service.port
					},
				]
			},
		]
	}
}
