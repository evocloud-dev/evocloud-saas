package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PvcBackend: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-media"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.backend.persistence.annotations != _|_ {
			annotations: #config.backend.persistence.annotations
		}
	}
	spec: {
		accessModes: #config.backend.persistence.accessModes
		if #config.backend.persistence.storageClassName != "" {
			storageClassName: #config.backend.persistence.storageClassName
		}
		if #config.backend.persistence.resources != _|_ {
			resources: #config.backend.persistence.resources
		}
	}
}
