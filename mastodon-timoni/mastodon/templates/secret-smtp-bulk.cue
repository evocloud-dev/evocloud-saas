package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SecretSMTPBulk: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name: "\(#config.metadata.name)-smtp-bulk"
		labels: #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		login:    #config.mastodon.smtp.bulk.login
		password: #config.mastodon.smtp.bulk.password
	}
}
