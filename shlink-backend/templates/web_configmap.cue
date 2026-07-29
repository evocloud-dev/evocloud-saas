package templates

import (
	corev1 "k8s.io/api/core/v1"
	"encoding/json"
)

#WebConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-web"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		"servers.json": json.Marshal(#config.web.configuration)
	}
}
