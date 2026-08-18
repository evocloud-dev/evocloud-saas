package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"
)

#HTTPRoute: {
	#config:    #Config
	apiVersion: #config.gatewayAPI.apiVersion
	kind:       "HTTPRoute"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "sonarqube"
	}
	metadata: {
		name: #config.fullname
		labels: "app.kubernetes.io/component": "sonarqube"
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
				if len(#config.gatewayAPI.filters) > 0 {
					filters: #config.gatewayAPI.filters
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
