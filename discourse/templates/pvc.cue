package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.#sharedClaimName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.persistence.annotations != _|_ {
			annotations: #config.persistence.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [
			for am in #config.persistence.accessModes {
				corev1.#PersistentVolumeAccessMode & am
			},
		]
		if #config.persistence.storageClass != "" {
			storageClassName: #config.persistence.storageClass
		}
		resources: requests: (corev1.#ResourceStorage): #config.persistence.size
	}
}
