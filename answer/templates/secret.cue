package templates

#SecretAdmin: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.adminSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"admin-password": #config.admin.password
	}
}

#SecretDatabase: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.databaseSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"database-password": #config.databasePasswordValue
	}
}

#SecretBackup: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-backup"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"access-key": #config.backup.s3.accessKey
		"secret-key": #config.backup.s3.secretKey
	}
}
