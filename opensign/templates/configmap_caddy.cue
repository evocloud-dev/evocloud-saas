package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#CaddyConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "caddyfile"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: {
		Caddyfile: #config.caddy.caddyfile
	}
}
