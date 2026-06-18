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
		namespace: #config.namespace
		labels:    #config.labels
		if #config.serviceAccount.annotations != _|_ {
			annotations: #config.serviceAccount.annotations
		}
	}
	automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
}
