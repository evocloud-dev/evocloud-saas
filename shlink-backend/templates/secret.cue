package templates

import corev1 "k8s.io/api/core/v1"

#DatabaseSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#databaseSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: corev1.#SecretTypeOpaque
	stringData: "\(#config.#databasePasswordKey)": #config.config.database.auth.password
}

#MatomoSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#matomoSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: corev1.#SecretTypeOpaque
	stringData: "api-token": #config.config.matomo.auth.apiToken
}

#MercureSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#mercureSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: corev1.#SecretTypeOpaque
	stringData: "jwt-secret": #config.config.mercure.auth.jwtSecret
}

#RabbitMQSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#rabbitmqSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: corev1.#SecretTypeOpaque
	stringData: "rabbitmq-password": #config.config.rabbitmq.auth.password
}
