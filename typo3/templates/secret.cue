package templates

import corev1 "k8s.io/api/core/v1"

#DatabaseSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name: #config.#databaseSecretName
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		"\(#config.#databasePasswordKey)": #config.externalDatabase.auth.password
	}
}