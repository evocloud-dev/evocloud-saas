package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name: [
			if #config.serviceAccount.name != "" {
				#config.serviceAccount.name
			},
			#config.fullname,
		][0]
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.serviceAccount.annotations != _|_ {
			annotations: #config.serviceAccount.annotations
		}
	}
}
