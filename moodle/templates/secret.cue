package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Secret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#secretName
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
		"\(#config.moodle.existingSecretPasswordKey)": #config.#adminPassword
	}
}
