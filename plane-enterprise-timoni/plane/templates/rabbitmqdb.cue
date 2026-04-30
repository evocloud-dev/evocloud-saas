package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#RabbitMQSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-rabbitmq-secrets"
	}
	type: "Opaque"
	stringData: {
		RABBITMQ_DEFAULT_USER: #config.services.rabbitmq.default_user
		RABBITMQ_DEFAULT_PASS: #config.services.rabbitmq.default_password
	}
}
