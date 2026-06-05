package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#AppSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._appSecretName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels
	}
	type: "Opaque"
	stringData: {
		(#config.secrets.app.appKeySecretKey):         #config.secrets.app.appKey
		(#config.secrets.app.jwtSecretKey):            #config.secrets.app.jwtSecret
		(#config.secrets.app.stripePublishableKeyKey): #config.secrets.app.stripePublishableKey
		(#config.secrets.app.stripeSecretKeyKey):      #config.secrets.app.stripeSecretKey
		(#config.secrets.app.stripeWebhookSecretKey):  #config.secrets.app.stripeWebhookSecret
	}
}

#PostgresqlSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._postgresSecretName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels
	}
	type: "Opaque"
	stringData: {
		(#config.secrets.postgresql.passwordKey): #config.secrets.postgresql.password
	}
}

#RedisSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._redisSecretName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels
	}
	type: "Opaque"
	stringData: {
		(#config.secrets.redis.passwordKey): #config.secrets.redis.password
	}
}

#MailSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._mailSecretName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels
	}
	type: "Opaque"
	stringData: {
		(#config.secrets.mail.passwordKey): #config.secrets.mail.password
	}
}

#S3Secret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._s3SecretName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels
	}
	type: "Opaque"
	stringData: {
		(#config.secrets.s3.accessKeyIdKey):     #config.secrets.s3.accessKeyId
		(#config.secrets.s3.secretAccessKeyKey): #config.secrets.s3.secretAccessKey
	}
}
