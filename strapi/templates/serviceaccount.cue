package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:        #config.fullname
		namespace:   #config.metadata.namespace
		labels:      #config.metadata.labels
		annotations: #config.serviceAccount.annotations
	}
	automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
}
