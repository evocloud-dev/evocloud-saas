package templates

#ExternalSecret: {
	#config: #Config

	apiVersion: #config.externalSecrets.apiVersion
	kind:       "ExternalSecret"
	metadata: {
		name:      #config.#proxyFullname
		namespace: #config.metadata.namespace
		labels:    #config.#labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		refreshInterval: #config.externalSecrets.refreshInterval
		secretStoreRef:  #config.externalSecrets.secretStoreRef
		target: {
			name:           #config.proxy.existingSecret
			creationPolicy: #config.externalSecrets.target.creationPolicy
		}
		if len(#config.externalSecrets.data) > 0 {
			data: #config.externalSecrets.data
		}
		if len(#config.externalSecrets.dataFrom) > 0 {
			dataFrom: #config.externalSecrets.dataFrom
		}
	}
}
