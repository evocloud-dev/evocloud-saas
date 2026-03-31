package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DatabaseSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.metadata.name + "-db"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		"database-url": #dbUrl
	}

	#dbUrl: {
		if #config.postgresql.enabled {
			"postgresql://\(#config.postgresql.auth.username):\(#config.postgresql.auth.password)@\(#config.metadata.name)-postgresql:5432/\(#config.postgresql.auth.database)"
		}
		if #config.mysql.enabled {
			"mysql://\(#config.mysql.auth.username):\(#config.mysql.auth.password)@\(#config.metadata.name)-mysql:3306/\(#config.mysql.auth.database)"
		}
		if !#config.postgresql.enabled && !#config.mysql.enabled {
			"\(#config.externalDatabase.type)://\(#config.externalDatabase.auth.username):\(#config.externalDatabase.auth.password)@\(#config.externalDatabase.hostname):\(#config.externalDatabase.port)/\(#config.externalDatabase.auth.database)"
		}
	}
}

#AppSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.metadata.name + "-app-secret"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		"app-secret": #config.umami.appSecret.#secret
	}
}
