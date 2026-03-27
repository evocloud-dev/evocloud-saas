package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DrupalService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.service.annotations != _|_ {
			annotations: #config.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type:     corev1.#ServiceTypeClusterIP
		selector: #config.selector.labels & {
			tier: "drupal"
		}
		ports: [
			{
				port:       9000
				protocol:   "TCP"
				name:       "tcp-php-fpm"
				targetPort: name
			},
		]
	}
}

#NginxService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-nginx"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.service.annotations != _|_ {
			annotations: #config.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type:     corev1.#ServiceTypeClusterIP
		selector: #config.selector.labels & {
			tier: "frontend"
		}
		ports: [
			{
				port:       8080
				protocol:   "TCP"
				name:       "http"
				targetPort: "http"
			},
			{
				port:       8443
				protocol:   "TCP"
				name:       "https"
				targetPort: "https"
			},
		]
	}
}
