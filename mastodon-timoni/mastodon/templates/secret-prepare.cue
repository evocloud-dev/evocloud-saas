package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SecretPrepare: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name: "\(#config.metadata.name)-prepare"
		labels: #config.metadata.labels
		annotations: {
			"helm.sh/hook":                "pre-install"
			"helm.sh/hook-delete-policy": "before-hook-creation,hook-succeeded"
			"helm.sh/hook-weight":         "-3"
		}
	}
	type: "Opaque"
	stringData: (#secretData & {#config: #config, prepare: true}).data
}
