package templates

#HTTPRoute: {
	#config: #Config

	let gatewayEnabled = #config.gateway.enabled
	let legacyEnabled = #config.gatewayAPI.enabled
	let useLegacyGateway = !gatewayEnabled && legacyEnabled

	let annotations = [if useLegacyGateway { #config.gatewayAPI.annotations }, #config.gateway.annotations][0]

	let parentRefs = [
		if useLegacyGateway {
			if len(#config.gatewayAPI.parentRefs) > 0 {
				#config.gatewayAPI.parentRefs
			}
			if len(#config.gatewayAPI.parentRefs) == 0 && #config.gatewayAPI.gatewayName != _|_ && #config.gatewayAPI.gatewayName != "" {
				[
					{
						name: #config.gatewayAPI.gatewayName
						if #config.gatewayAPI.gatewayNamespace != _|_ && #config.gatewayAPI.gatewayNamespace != "" {
							namespace: #config.gatewayAPI.gatewayNamespace
						}
					},
				]
			}
		}
		if !useLegacyGateway {
			#config.gateway.parentRefs
		}
	][0]

	let hostnames = [if useLegacyGateway { #config.gatewayAPI.hostnames }, #config.gateway.hostnames][0]

	let matches = [
		if useLegacyGateway {
			if len(#config.gatewayAPI.paths) > 0 {
				[
					for p in #config.gatewayAPI.paths {
						let legacyPath = [if p.path != _|_ { p.path }, [if p.value != _|_ { p.value }, "/"][0]][0]
						let legacyPathType = [if p.pathType != _|_ { p.pathType }, [if p.type != _|_ { p.type }, "PathPrefix"][0]][0]
						{
							pathType: legacyPathType
							path:     legacyPath
						}
					},
				]
			}
			if len(#config.gatewayAPI.paths) == 0 {
				[
					{
						pathType: #config.gatewayAPI.pathType
						path:     #config.gatewayAPI.path
					},
				]
			}
		}
		if !useLegacyGateway {
			[
				{
					pathType: #config.gateway.pathType
					path:     #config.gateway.path
				},
			]
		}
	][0]

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      #config.fullname
		namespace: #config.namespace
		labels:    #config.labels
		if annotations != _|_ && len(annotations) > 0 {
			"annotations": annotations
		}
	}
	spec: {
		if parentRefs != _|_ && len(parentRefs) > 0 {
			"parentRefs": parentRefs
		}
		if hostnames != _|_ && len(hostnames) > 0 {
			"hostnames": hostnames
		}
		rules: [
			{
				"matches": [
					for m in matches {
						path: {
							type:  m.pathType
							value: m.path
						}
					},
				]
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
