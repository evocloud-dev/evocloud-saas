package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#IdentitySecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-identity"
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
		AUTH_SECRET: [
			if #config.identity.authSecret != "" {#config.identity.authSecret},
			"DefaultReactiveResumeAuthSecretForTokenSigningAndSessionValidation64Char",
		][0]
		ENCRYPTION_SECRET: [
			if #config.identity.encryptionSecret != "" {#config.identity.encryptionSecret},
			"DefaultReactiveResumeEncryptionSecretForDataProtectionAndKeys64Char",
		][0]
	}
}

