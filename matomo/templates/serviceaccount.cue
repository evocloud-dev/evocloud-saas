package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// Define the schema mapping placeholder first so CUE can read it
#ServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      #saName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels

		if #config.serviceAccount.annotations != _|_ && #config.serviceAccount.annotations != {} {
			annotations: #config.serviceAccount.annotations
		}
	}

	#saName: {
		if #config.serviceAccount.name != "" {
			#config.serviceAccount.name
		}
		if #config.serviceAccount.name == "" {
			#config.metadata.name
		}
	}
	automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
}
