package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#GCSSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-gcs-credentials"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"credentials.json": #config.storage.gcs.credentials.jsonKey
	}
}
