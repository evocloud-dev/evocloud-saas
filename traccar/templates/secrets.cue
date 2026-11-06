package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#CNPGUrlsSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	type:       "Opaque"
	metadata: {
		name:      "\(#config.metadata.name)-cnpg-main-urls"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	stringData: {
		host:     "\(#config.metadata.name)-cnpg-main-rw"
		jdbc:     "jdbc:postgresql://\(#config.metadata.name)-cnpg-main-rw:\(#config.cnpg.port)/\(#config.cnpg.database)"
		nossl:    "postgresql://\(#config.cnpg.user):\(#config.cnpg.password)@\(#config.metadata.name)-cnpg-main-rw:\(#config.cnpg.port)/\(#config.cnpg.database)?sslmode=disable"
		porthost: "\(#config.metadata.name)-cnpg-main-rw:\(#config.cnpg.port)"
		std:      "postgresql://\(#config.cnpg.user):\(#config.cnpg.password)@\(#config.metadata.name)-cnpg-main-rw:\(#config.cnpg.port)/\(#config.cnpg.database)"
	}
}

#CNPGUserSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	type:       "kubernetes.io/basic-auth"
	metadata: {
		name:      "\(#config.metadata.name)-cnpg-main-user"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	stringData: {
		password: #config.cnpg.password
		username: #config.cnpg.user
	}
}

