package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-config"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.persistence.config.accessModes
		resources: {
			requests: {
				storage: #config.persistence.config.size
			}
		}
		if #config.persistence.config.storageClass != _|_ {
			storageClassName: #config.persistence.config.storageClass
		}
	}
}

