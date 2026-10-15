package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#BootstrapSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._bootstrapSecretName
		namespace: #config.metadata.namespace
		labels:    #config._labels
		annotations: {
			"helm.sh/resource-policy": "keep"
			if #config.metadata.annotations != _|_ {
				#config.metadata.annotations
			}
		}
	}
	type: "Opaque"
	stringData: {
		"\(#config.bootstrap.passwordKey)": #config._bootstrapPassword
	}
}

