package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-sitesdirectory"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.persistence.sitesdirectory.accessModes
		resources: {
			requests: {
				storage: #config.persistence.sitesdirectory.size
			}
		}
		if #config.persistence.sitesdirectory.storageClass != _|_ {
			storageClassName: #config.persistence.sitesdirectory.storageClass
		}
	}
}
