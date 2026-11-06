package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata:   #config.metadata
	if #config.serviceAccount.name != "" {
		metadata: name: #config.serviceAccount.name
	}
	if #config.serviceAccount.annotations != _|_ {
		metadata: annotations: #config.serviceAccount.annotations
	}
}
