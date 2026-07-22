package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceMedia: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-media"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.serviceMedia.annotations != _|_ {
			annotations: #config.serviceMedia.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type:         "ExternalName"
		externalName: #config.serviceMedia.host
	}
}