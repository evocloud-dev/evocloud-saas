package templates

#ConfigMap: {
	#config: #Config
	#helpers: #Helpers

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #helpers.fullname
		namespace: #config.metadata.namespace
		labels:    #helpers.labels
	}
	data: {
		LISTMONK_app__address:     #config.app.address
		LISTMONK_app__lang:        #config.app.lang
		LISTMONK_db__host:         #config.database.host
		LISTMONK_db__port:         "\(#config.database.port)"
		LISTMONK_db__user:         #config.database.user
		LISTMONK_db__database:     #config.database.name
		LISTMONK_db__ssl_mode:     #config.database.sslMode
		LISTMONK_db__max_open:     "\(#config.database.maxOpen)"
		LISTMONK_db__max_idle:     "\(#config.database.maxIdle)"
		LISTMONK_db__max_lifetime: #config.database.maxLifetime
		"config.toml": """
			[app]
			address = \"\(#config.app.address)\"
			lang = \"\(#config.app.lang)\"

			[db]
			host = \"\(#config.database.host)\"
			port = \(#config.database.port)
			user = \"\(#config.database.user)\"
			database = \"\(#config.database.name)\"
			ssl_mode = \"\(#config.database.sslMode)\"
			max_open = \(#config.database.maxOpen)
			max_idle = \(#config.database.maxIdle)
			max_lifetime = \"\(#config.database.maxLifetime)\"
			params = ""
			"""
	}
}
