package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SecretElasticsearch: corev1.#Secret & {
	#config: #Config
	#name:   "\(#config.metadata.name)-elasticsearch"

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name:      #name
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"elastic-password": "mastodon_development"
	}
}
