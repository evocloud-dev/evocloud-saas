package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ProofKeySecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name: [if #config.collabora.proofKeyGeneration.secretName != "" {#config.collabora.proofKeyGeneration.secretName}, "\(#config.metadata.name)-wopi-proof"][0]
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	type: "Opaque"
	data: {
		if #config.collabora.proofKey != _|_ {
			proof_key: #config.collabora.proofKey
		}
	}
}

