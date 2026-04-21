package templates

#HTTPRouteStreaming: {
	#config: #Config

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		namespace: #config.#namespace
		name: "\(#config.metadata.name)-streaming"
		labels: #config.metadata.labels & #config.httproute.labels
		if #config.httproute.annotations != _|_ {
			annotations: #config.httproute.annotations
		}
	}
	spec: {
		parentRefs: [
			if len(#config.httproute.streamingParentRefs) > 0 for r in #config.httproute.streamingParentRefs {r},
			if len(#config.httproute.streamingParentRefs) == 0 for r in #config.httproute.parentRefs {r},
		]
		hostnames: [
			if len(#config.httproute.streamingHostnames) > 0 for r in #config.httproute.streamingHostnames {r},
			if len(#config.httproute.streamingHostnames) == 0 for r in #config.httproute.hostnames {r},
		]
		rules: [
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
			},
		]
	}
}
