package templates

import corev1 "k8s.io/api/core/v1"

#ServiceAccount: corev1.#ServiceAccount & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: #config.metadata & {
		name: #config.#serviceAccountName
		if len(#config.serviceAccount.annotations) > 0 {
			annotations: #config.serviceAccount.annotations
		}
	}
}