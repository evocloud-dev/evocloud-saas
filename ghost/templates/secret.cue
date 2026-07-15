package templates

import corev1 "k8s.io/api/core/v1"

#DatabaseSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.#serviceName)-db"
		namespace: #config.metadata.namespace
		labels:    #config.labels
	}
	type: "Opaque"
	stringData: password: #config.database.external.password
}

#BackupSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.#serviceName)-backup"
		namespace: #config.metadata.namespace
		labels:    #config.labels
	}
	type: "Opaque"
	stringData: {
		"access-key": #config.backup.s3.accessKey
		"secret-key": #config.backup.s3.secretKey
	}
}