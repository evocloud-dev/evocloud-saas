// SPDX-License-Identifier: Apache-2.0
package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceBuilder: {
	_config:   #Config
	_fullname: string

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      _fullname
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels & _config.commonLabels
		if _config.service.annotations != _|_ {
			annotations: _config.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: _config.service.type
		if _config.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: _config.service.ipFamilyPolicy
		}
		if len(_config.service.ipFamilies) > 0 {
			ipFamilies: _config.service.ipFamilies
		}
		ports: [{
			name:       "http"
			port:       _config.service.port
			targetPort: "http"
			protocol:   "TCP"
		}]
		selector: _config.metadata.labels
	}
}
