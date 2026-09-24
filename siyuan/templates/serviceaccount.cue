package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      #config.serviceAccountName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.metadata.annotations != _|_ {
				for k, v in #config.metadata.annotations {
					(k): v
				}
			}
			if #config.serviceAccount.annotations != _|_ {
				for k, v in #config.serviceAccount.annotations {
					(k): v
				}
			}
		}
	}
	automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
}
