package templates

#HTTPRoute: {
	#config: #Config
	apiVersion: "gateway.networking.k8s.io/v1"
	kind:       "HTTPRoute"
	metadata:   #config.metadata
	spec: {
		parentRefs: [...{
			name:        string
			namespace?:  string
		}]
		
		if #config.gateway.hostnames != _|_ {
			hostnames: [...string]
		}
		
		rules: [...{
			matches?: [...{
				path?: {
					type?:  string
					value?: string
				}
			}]
			backendRefs: [...{
				name:  string
				port?: int
			}]
		}]
	}
}
