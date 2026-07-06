package templates

import corev1 "k8s.io/api/core/v1"

#WebServiceAccount: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      #config.web.#serviceAccountName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.web.serviceAccount.annotations) > 0 {
			annotations: #config.web.serviceAccount.annotations
		}
	}
}
