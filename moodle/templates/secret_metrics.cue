package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SecretMetrics: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#metricsSecret
		namespace: #config.metadata.namespace
		labels:    #config.#labels
		annotations: {
			"helm.sh/resource-policy": "keep"
			if #config.metadata.annotations != _|_ {
				for k, v in #config.metadata.annotations {
					"\(k)": v
				}
			}
		}
	}
	type: "Opaque"
	stringData: {
		"\(#config.metrics.existingSecretTokenKey)": "default-moodle-metrics-bearer-token-48-chars"
	}
}
