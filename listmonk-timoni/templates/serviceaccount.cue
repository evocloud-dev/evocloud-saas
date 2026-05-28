package templates

#ServiceAccount: {
	#config: #Config
	#helpers: #Helpers

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      #helpers.serviceAccountName
		namespace: #config.metadata.namespace
		labels:    #helpers.labels
		if #config.serviceAccount.annotations != _|_ {
			annotations: #config.serviceAccount.annotations
		}
	}
}
