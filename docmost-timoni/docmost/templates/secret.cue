package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DatabaseSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-database"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"database-password": {
			if #config.database.external.password != "" { #config.database.external.password }
			if #config.database.external.password == "" { "postgres-default-pass-change-me" }
		}
	}
}

#AppSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-app"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"app-secret": {
			if #config.docmost.appSecret != "" { #config.docmost.appSecret }
			if #config.docmost.appSecret == "" { "default-change-me-64-character-app-secret-token-key-for-docmost" }
		}
	}
}

#RedisSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"redis-password": {
			if #config.redis.external.password != "" { #config.redis.external.password }
			if #config.redis.external.password == "" { "redis-default-pass-change-me" }
		}
	}
}

#StorageSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-storage"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"access-key": #config.storage.s3.accessKey
		"secret-key": #config.storage.s3.secretKey
	}
}

#BackupSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-backup"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"\(#config.backup.s3.existingSecretAccessKeyKey)": #config.backup.s3.accessKey
		"\(#config.backup.s3.existingSecretSecretKeyKey)": #config.backup.s3.secretKey
	}
}
