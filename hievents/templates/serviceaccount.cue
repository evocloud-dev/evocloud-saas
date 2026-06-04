package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      #config._saName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels
		if len(#config.serviceAccount.annotations) > 0 {
			annotations: #config.serviceAccount.annotations
		}
	}
}
