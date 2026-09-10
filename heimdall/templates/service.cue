package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceBuilder: corev1.#Service & {
	_config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      _config.fullname
		namespace: _config.namespace
		labels:    _config.standardLabels
		if len(_config.service.annotations) > 0 {
			annotations: _config.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: _config.service.type
		ports: [{
			name:       "http"
			port:       _config.service.port
			targetPort: "http"
			protocol:   "TCP"
		}]
		selector: _config.selectorLabels
	}
}
