package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#NginxConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-nginx-config"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name": "\(#config.metadata.name)-nginx-config"
		}
	}
	data: {
		"default.conf": #config.nginx.config
	}
}
