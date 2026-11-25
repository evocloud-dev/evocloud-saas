package templates

// #HTTPRoute mirrors templates/httproute.yaml.
#HTTPRoute: {
	#config: #Config

	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.commonAnnotations) > 0 || len(#config.gateway.annotations) > 0 {
			annotations: {
				for k, v in #config.commonAnnotations if #config.gateway.annotations[k] == _|_ {(k): v}
				#config.gateway.annotations
			}
		}
	}
	spec: {
		parentRefs: #config.gateway.parentRefs
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
