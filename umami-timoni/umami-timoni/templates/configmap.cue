package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata:   #config.metadata
	data: {
		"\(#config.umami.customScript.key)": #config.umami.customScript.data
	}
}
