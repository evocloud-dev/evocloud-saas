// SPDX-License-Identifier: Apache-2.0
package templates

#HTTPRoute: {
	#config: #Config

	apiVersion: #config.route.apiVersion
	kind:       #config.route.kind
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.route.annotations != _|_ {
			annotations: #config.route.annotations
		}
	}
	spec: {
		if #config.route.parentRefs != _|_ {
			parentRefs: #config.route.parentRefs
		}
		if #config.route.hostnames != _|_ {
			if len(#config.route.hostnames) > 0 {
				hostnames: #config.route.hostnames
			}
		}
		rules: [{
			matches: [{
				path: {
					type:  #config.route.pathType
					value: #config.route.path
				}
			}]
			backendRefs: [{
				name: #config.metadata.name
				port: #config.service.port
			}]
		}]
	}
}
