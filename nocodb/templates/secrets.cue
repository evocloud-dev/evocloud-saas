package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#CnpgUrlsSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-cnpg-main-urls"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		host:     "\(#config.metadata.name)-cnpg-main-rw"
		jdbc:     "jdbc:postgresql://\(#config.metadata.name)-cnpg-main-rw:5432/\(#config.cnpg.main.database)"
		nossl:    "postgresql://\(#config.cnpg.main.user):\(#config.cnpg.main.password)@\(#config.metadata.name)-cnpg-main-rw:5432/\(#config.cnpg.main.database)?sslmode=disable"
		porthost: "\(#config.metadata.name)-cnpg-main-rw:5432"
		std:      "postgresql://\(#config.cnpg.main.user):\(#config.cnpg.main.password)@\(#config.metadata.name)-cnpg-main-rw:5432/\(#config.cnpg.main.database)"
	}
}

#CnpgUserSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-cnpg-main-user"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "kubernetes.io/basic-auth"
	stringData: {
		username: #config.cnpg.main.user
		password: #config.cnpg.main.password
	}
}

#NocodbSecrets: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-secrets"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		NC_AUTH_JWT_SECRET: #config.workload.main.podSpec.containers.main.env.NC_AUTH_JWT_SECRET
	}
}
