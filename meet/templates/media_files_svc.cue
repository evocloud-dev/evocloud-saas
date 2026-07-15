package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceMediaFiles: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-media-files"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.serviceMediaFiles.annotations != _|_ {
			annotations: #config.serviceMediaFiles.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type:         "ExternalName"
		externalName: #config.serviceMediaFiles.host
	}
}