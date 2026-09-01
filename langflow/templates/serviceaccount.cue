// SPDX-License-Identifier: Apache-2.0
package templates

#ServiceAccountBuilder: {
	_config:             #Config
	_serviceAccountName: string

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      _serviceAccountName
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels & _config.commonLabels
		if _config.serviceAccount.annotations != _|_ {
			annotations: _config.serviceAccount.annotations
		}
	}
	automountServiceAccountToken: _config.serviceAccount.automountServiceAccountToken
}
