package templates

#Secret: {
	#config: #Config
	#helpers: #Helpers

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #helpers.smtpSecretName
		namespace: #config.metadata.namespace
		labels:    #helpers.labels
	}
	type: "Opaque"
	stringData: {
		"smtp-host":     #config.smtp.host
		"smtp-port":     "\(#config.smtp.port)"
		"smtp-username": #config.smtp.username
		"smtp-password": #config.smtp.password
		"smtp-from":     #config.smtp.from
	}
}
