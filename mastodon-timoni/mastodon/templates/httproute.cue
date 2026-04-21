package templates

#HTTPRouteWeb: {
	#config: #Config

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		namespace: #config.#namespace
		name: #config.metadata.name
		labels: #config.metadata.labels & #config.httproute.labels
		if #config.httproute.annotations != _|_ {
			annotations: #config.httproute.annotations
		}
	}
	spec: {
		parentRefs: #config.httproute.parentRefs
		hostnames:  #config.httproute.hostnames
		rules: [
			for r in #config.httproute.rules {
				if r.matches != _|_ {
					matches: r.matches
				}
				if r.filters != _|_ {
					filters: r.filters
				}
				backendRefs: [
					{
						group: ""
						kind:  "Service"
						name:  "\(#config.metadata.name)-web"
						port:  #config.mastodon.web.port
						weight: 1
					},
				]
			},
			if len(#config.httproute.streamingHostnames) == 0 {
				for r in #config.httproute.streamingRules {
					if r.matches != _|_ {
						matches: r.matches
					}
					if r.filters != _|_ {
						filters: r.filters
					}
					backendRefs: [
						{
							group: ""
							kind:  "Service"
							name:  "\(#config.metadata.name)-streaming"
							port:  #config.mastodon.streaming.port
							weight: 1
						},
					]
				}
			},
		]
	}
}
