package templates

import (
	gatewayv1 "gateway.networking.k8s.io/httproute/v1"
)

#GatewayHttpRoute: {
	#config: #Config
	#route:  _
	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata:   #config.metadata & {
		name: #route.name
		if #route.annotations != _|_ {
			annotations: #route.annotations
		}
	}
	spec: gatewayv1.#HTTPRouteSpec & {
		parentRefs: #route.parentRef
		if #route.hostnames != _|_ {
			hostnames: #route.hostnames
		}
		rules: [ for rule in #route.rules {
			matches:     rule.matches
			filters:     rule.filters
			backendRefs: rule.backendRefs
		} ]
	}
}
