package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#WorkerPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.persistence.worker.accessModes
		resources: requests: storage: #config.persistence.worker.size
		if #config.persistence.worker.storageClass != "" {
			storageClassName: #config.persistence.worker.storageClass
		}
	}
}
