package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      #config.#serviceAccountName
		namespace: #config.metadata.namespace
		labels:    #config.#labels
		if #config.serviceAccount.annotations != _|_ && len(#config.serviceAccount.annotations) > 0 {
			annotations: #config.serviceAccount.annotations
		}
	}
	automountServiceAccountToken: false
}
