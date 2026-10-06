package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#BootstrapSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-bootstrap"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.metadata.annotations != _|_ {
				#config.metadata.annotations
			}
			"helm.sh/resource-policy": "keep"
		}
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		"\(#config.bootstrap.passwordKey)": [
			if #config.bootstrap.password != "" {#config.bootstrap.password},
			"ReactiveResumeInitialPassword2026!",
		][0]
	}
}

