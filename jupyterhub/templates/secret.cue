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
		labels:    #config.#componentLabels & {#component: "proxy"}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: corev1.#SecretTypeOpaque
	if #config.proxy.secretData != null {
		data: {
			"\(#config.proxy.existingSecretTokenKey)": #config.proxy.secretData
		}
	}
	if #config.proxy.secretData == null {
		stringData: {
			"\(#config.proxy.existingSecretTokenKey)": #config.proxy.secretToken
		}
	}
}
