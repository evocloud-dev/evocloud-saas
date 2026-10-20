package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SemaphoreSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	type:       corev1.#SecretTypeOpaque
	metadata: {
		name:      "\(#config.metadata.name)-semaphore-secrets"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "semaphore-secrets"
		}
	}
	stringData: {
		SEMAPHORE_ACCESS_KEY_ENCRYPTION: #config.semaphore.accessKeyEncryption
	}
}
