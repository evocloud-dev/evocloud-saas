package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// #NginxConfigMap is the literal CUE translation of nginx-config.yaml.
#NginxConfigMap: corev1.#ConfigMap & {
	#in: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		for k, v in #in.metadata if k != "name" {
			"\(k)": v
		}
		name:      "\(#in.metadata.name)-nginxconfig"
	}

	data: {
		if #in.nginx.config.default {
			"default.conf": (#NginxConfigTpl & {#in: #in}).out
		}
		if #in.nginx.config.custom != _|_ {
			"zz-custom.conf": #in.nginx.config.custom
		}
	}
}
