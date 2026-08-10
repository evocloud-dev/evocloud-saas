package templates

import (
	"struct"
)

#HTTPRoute: {
	#config: #Config
	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      #config.fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if struct.MinFields(#config.gateway.annotations, 1) {
			annotations: #config.gateway.annotations
		}
	}
	spec: {
		parentRefs: [
			for parent in #config.gateway.parentRefs {
				{
					name: parent.name
					if parent.namespace != _|_ && parent.namespace != "" {
						namespace: parent.namespace
					}
				}
			},
		]
		if len(#config.gateway.hostnames) > 0 {
			hostnames: #config.gateway.hostnames
		}
		rules: [
			{
				matches: [
					{
						path: {
							type:  #config.gateway.pathType
							value: #config.gateway.path
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
