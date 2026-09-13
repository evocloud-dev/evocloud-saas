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
		labels:    _config.metadata.labels & _config.commonLabels
		if len(_config.service.annotations) > 0 {
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
		ports: [
			{
				name:       "http"
				port:       _config.service.port
				targetPort: "http"
				protocol:   "TCP"
			},
			if _config.taskRunners.mode == "external" {
				name:       "runners"
				port:       5679
				targetPort: 5679
				protocol:   "TCP"
			},
		]
		selector: _config.selector.labels
	}
}
