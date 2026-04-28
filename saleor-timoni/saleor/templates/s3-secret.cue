package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#S3Secret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-s3-credentials"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		if #config.storage.s3.credentials.accessKeyId != "" {
			"AWS_ACCESS_KEY_ID": #config.storage.s3.credentials.accessKeyId
		}
		if #config.storage.s3.credentials.secretAccessKey != "" {
			"AWS_SECRET_ACCESS_KEY": #config.storage.s3.credentials.secretAccessKey
		}
	}
}
