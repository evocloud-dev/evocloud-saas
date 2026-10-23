package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#AdminSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#secretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		"limesurvey-admin-password": #config.#adminPassword
	}
}

#ExternalDatabaseSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#databaseSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		"mariadb-password": #config.externalDatabase.password
	}
}

#SmtpSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#smtpSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		if #config.limesurvey.smtp.user != "" {
			"limesurvey-smtp-user": #config.limesurvey.smtp.user
		}
		"limesurvey-smtp-password": #config.#smtpPassword
	}
}
