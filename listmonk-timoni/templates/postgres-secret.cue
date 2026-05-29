package templates

#PostgresSecret: {
	#config: #Config
	#helpers: #Helpers

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #helpers.dbSecretName
		namespace: #config.metadata.namespace
		labels:    #helpers.labels
	}
	type: "Opaque"
	stringData: {
		username: #config.database.user
		database: #config.database.name
		password: #config.database.password
	}
}
