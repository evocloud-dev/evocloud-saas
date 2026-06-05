package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata:   #config.metadata
	if #config.persistence.annotations != _|_ {
		metadata: annotations: #config.persistence.annotations
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [ #config.persistence.accessMode ]
		resources: requests: storage: #config.persistence.size
		if #config.persistence.storageClass != _|_ {
			if #config.persistence.storageClass == "-" {
				storageClassName: ""
			}
			if #config.persistence.storageClass != "-" {
				storageClassName: #config.persistence.storageClass
			}
		}
	}
}
