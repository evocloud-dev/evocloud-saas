package templates

#ExternalSecret: {
	#config: #Config
	apiVersion: "external-secrets.io/v1"
	kind:       "ExternalSecret"
	metadata:   #config.metadata
	spec: {
		refreshInterval: string
		secretStoreRef: {
			name: string
			kind: string
		}
		target: {
			name:            string
			creationPolicy?: string
		}
		// Correct way to specify an optional list of open objects in CUE
		data?: [...]
	}
}
