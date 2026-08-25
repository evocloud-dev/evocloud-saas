package templates

#ServiceAccount: {
	#config: #Config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      #config.serviceAccountName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.serviceAccount.annotations) > 0 {
			annotations: #config.serviceAccount.annotations
		}
	}
}
