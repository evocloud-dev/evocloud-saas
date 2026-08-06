package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#AppSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.appSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		if #config.wallabag.secret != "" {
			"symfony-secret": #config.wallabag.secret
		}
		if #config.wallabag.secret == "" {
			"symfony-secret": "change-me-please-32-chars-long!"
		}
	}
}

#DBSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.dbSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		password: #config.database.external.password
	}
}

#BackupSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.backupSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"access-key": #config.backup.s3.accessKey
		"secret-key": #config.backup.s3.secretKey
	}
}

#AdminSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"wallabag-username": #config.wallabag.adminUser.username
		"wallabag-email":    #config.wallabag.adminUser.email
		"wallabag-password": #config.wallabag.adminUser.password
	}
}
