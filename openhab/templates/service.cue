package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      _config.fullname
		namespace: _config.namespace
		labels:    _config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: _config.service.type
		ports: [{
			name:       "http"
			port:       _config.service.port
			targetPort: "http"
			protocol:   "TCP"
		}]
		selector: _config.selector.labels
		if _config.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: _config.service.ipFamilyPolicy
		}
		if len(_config.service.ipFamilies) > 0 {
			ipFamilies: _config.service.ipFamilies
		}
	}
}

#KarafServiceBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(_config.fullname)-karaf"
		namespace: _config.namespace
		labels:    _config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: _config.karaf.service.type
		ports: [{
			name:       "karaf"
			port:       _config.karaf.service.port
			targetPort: "karaf"
			protocol:   "TCP"
		}]
		selector: _config.selector.labels
		if _config.karaf.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: _config.karaf.service.ipFamilyPolicy
		}
		if len(_config.karaf.service.ipFamilies) > 0 {
			ipFamilies: _config.karaf.service.ipFamilies
		}
	}
}
