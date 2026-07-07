package templates

import corev1 "k8s.io/api/core/v1"

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.#contentClaimName
		namespace: #config.metadata.namespace
		labels:    #config.labels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.persistence.accessModes
		if #config.persistence.storageClass != "" {
			storageClassName: #config.persistence.storageClass
		}
		resources: requests: storage: #config.persistence.size
	}
}