package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccountApi: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		if #config.api.serviceAccount.name != "" {
			name: #config.api.serviceAccount.name
		}
		if #config.api.serviceAccount.name == "" {
			name: "\(#config.metadata.name)-api"
		}
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-api"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/version":    #config.moduleVersion
			"app.kubernetes.io/managed-by": "timoni"
		}
		if #config.api.serviceAccount.annotations != _|_ {
			annotations: #config.api.serviceAccount.annotations
		}
	}
}
