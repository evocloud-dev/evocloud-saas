package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PlaneServiceAccount: corev1.#ServiceAccount & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	automountServiceAccountToken: true
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-srv-account"
	}
	if #config.dockerRegistry.enabled {
		imagePullSecrets: [
			if #config.dockerRegistry.existingSecret != "" {
				{name: #config.dockerRegistry.existingSecret}
			},
			if #config.dockerRegistry.existingSecret == "" {
				{name: "\(#config.metadata.name)-docker-registry-credentials"}
			},
		]
	}
}
