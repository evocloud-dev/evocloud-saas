package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#EncryptionSecretBuilder: corev1.#Secret & {
	_config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      _config.encryptionKeySecretName
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	type: "Opaque"
	stringData: {
		if _config.n8n.encryptionKey != "" {
			"encryption-key": _config.n8n.encryptionKey
		}
		if _config.n8n.encryptionKey == "" {
			"encryption-key": "CHANGE_ME_N8N_ENCRYPTION_KEY_32"
		}
	}
}

#TaskRunnersSecretBuilder: corev1.#Secret & {
	_config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      _config.taskRunnerSecretName
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	type: "Opaque"
	stringData: {
		if _config.taskRunners.authToken != "" {
			"auth-token": _config.taskRunners.authToken
		}
		if _config.taskRunners.authToken == "" {
			"auth-token": "CHANGE_ME_N8N_RUNNERS_AUTH_TOKEN"
		}
	}
}

#DatabaseSecretBuilder: corev1.#Secret & {
	_config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      _config.dbSecretName
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	type: "Opaque"
	stringData: {
		if _config.dbPasswordValue != "" {
			"database-password": _config.dbPasswordValue
		}
		if _config.dbPasswordValue == "" {
			"database-password": "CHANGE_ME_N8N_DATABASE_PASSWORD"
		}
	}
}

#RedisQueueSecretBuilder: corev1.#Secret & {
	_config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      _config.redisSecretName
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	type: "Opaque"
	stringData: {
		"redis-password": _config.queue.external.password
	}
}

#BackupSecretBuilder: corev1.#Secret & {
	_config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      _config.backupSecretName
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	type: "Opaque"
	stringData: {
		"access-key": _config.backup.s3.accessKey
		"secret-key": _config.backup.s3.secretKey
	}
}
