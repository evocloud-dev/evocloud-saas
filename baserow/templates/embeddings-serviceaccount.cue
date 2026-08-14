package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccountEmbeddings: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		if #config.embeddings.serviceAccount.name != "" {
			name: #config.embeddings.serviceAccount.name
		}
		if #config.embeddings.serviceAccount.name == "" {
			name: "\(#config.metadata.name)-embeddings"
		}
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.embeddings.serviceAccount.annotations != _|_ {
			annotations: #config.embeddings.serviceAccount.annotations
		}
	}
}
