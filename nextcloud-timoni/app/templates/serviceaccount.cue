package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#in:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      #in.rbac.serviceAccount.name
		namespace: #in.metadata.namespace
		labels:    #in.metadata.labels
		if #in.rbac.serviceAccount.annotations != _|_ {
			annotations: #in.rbac.serviceAccount.annotations
		}
	}
}
