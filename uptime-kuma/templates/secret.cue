package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DBSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config._name)-db"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		password: #config.database.external.password
	}
}

#BackupSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._backupSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"\(#config.backup.s3.existingSecretAccessKeyKey)": #config.backup.s3.accessKey
		"\(#config.backup.s3.existingSecretSecretKeyKey)": #config.backup.s3.secretKey
	}
}
