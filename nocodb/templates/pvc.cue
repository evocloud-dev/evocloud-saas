package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DataPVC: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-data"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [
			for mode in #config.persistence.data.accessModes {
				corev1.#PersistentVolumeAccessMode & mode
			},
		]
		resources: requests: (corev1.#ResourceName & "storage"): #config.persistence.data.storage
	}
}
