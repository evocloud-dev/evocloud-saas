package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// #PhpConfigMap emits the nextcloud-phpconfig ConfigMap.
// This is the Timoni equivalent of Helm's php-config.yaml.
//
// Helm:
//   {{- if .Values.nextcloud.phpConfigs -}}
//   data:
//     {{- range $key, $value := .Values.nextcloud.phpConfigs }}
//     {{ $key }}: |-
//       {{- $value | nindent 4 }}
//     {{- end }}
//   {{- end }}
//
// Timoni: uses a CUE for loop over #in.nextcloud.phpConfigs.
#PhpConfigMap: corev1.#ConfigMap & {
	#in:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#in.metadata.name)-phpconfig"
		namespace: #in.metadata.namespace
		labels:    #in.metadata.labels
		if #in.metadata.annotations != _|_ {
			annotations: #in.metadata.annotations
		}
	}
	data: {
		for key, value in #in.nextcloud.phpConfigs {
			"\(key)": value
		}
	}
}
