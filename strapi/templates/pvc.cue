package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:        "\(#config.fullname)-data"
		namespace:   #config.metadata.namespace
		labels:      #config.metadata.labels
		annotations: #config.persistence.annotations
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.persistence.accessMode]
		if #config.persistence.storageClass != "" {
			storageClassName: #config.persistence.storageClass
		}
		resources: requests: (corev1.#ResourceList & {
			(corev1.#ResourceStorage): #config.persistence.size
		})
	}
}
