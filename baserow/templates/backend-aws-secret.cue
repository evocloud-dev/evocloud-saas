package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SecretAwsBackend: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-aws"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		if #config.minio.enabled {
			"access-key-id":     #config.minio.auth.rootUser
			"secret-access-key": #config.minio.auth.rootPassword
		}
		if !#config.minio.enabled {
			"access-key-id":     #config.backend.config.aws.accessKeyId
			"secret-access-key": #config.backend.config.aws.secretAccessKey
		}
	}
}
