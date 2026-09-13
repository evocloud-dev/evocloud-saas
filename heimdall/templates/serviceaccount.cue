package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccountBuilder: corev1.#ServiceAccount & {
	_config: #Config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      _config.serviceAccountName
		namespace: _config.namespace
		labels:    _config.standardLabels
		if len(_config.serviceAccount.annotations) > 0 {
			annotations: _config.serviceAccount.annotations
		}
	}
	automountServiceAccountToken: _config.serviceAccount.automountServiceAccountToken
}
