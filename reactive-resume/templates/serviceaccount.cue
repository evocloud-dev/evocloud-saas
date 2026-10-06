package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config: #Config

	_saName: [
		if #config.serviceAccount.name != "" {#config.serviceAccount.name},
		#config.metadata.name,
	][0]

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      _saName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.serviceAccount.annotations != _|_ {
			annotations: #config.serviceAccount.annotations
		}
	}
	automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
}
