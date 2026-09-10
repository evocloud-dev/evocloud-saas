package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#BackupSecretBuilder: corev1.#Secret & {
	_config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      _config.backupSecretName
		namespace: _config.namespace
		labels:    _config.standardLabels
	}
	type: "Opaque"
	stringData: {
		"access-key": _config.backup.s3.accessKey
		"secret-key": _config.backup.s3.secretKey
	}
}

