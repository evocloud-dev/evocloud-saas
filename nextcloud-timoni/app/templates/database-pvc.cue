package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// #DatabasePVC defines a reusable PVC for database engines.
#DatabasePVC: corev1.#PersistentVolumeClaim & {
	#in: #Config
	#persistence: {
		enabled:      bool
		storageClass: string
		accessMode:   corev1.#PersistentVolumeAccessMode
		size:         string
	}
	#name: string

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"

	metadata: {
		name:      #name
		namespace: #in.metadata.namespace
		labels:    #in.metadata.labels
	}

	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#persistence.accessMode]
		resources: requests: storage: #persistence.size

		if #persistence.storageClass == "-" {
			storageClassName: ""
		}
		if #persistence.storageClass != "" && #persistence.storageClass != "-" {
			storageClassName: #persistence.storageClass
		}
	}
}
