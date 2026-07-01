package templates

import corev1 "k8s.io/api/core/v1"

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config

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
		accessModes: [corev1.#ReadWriteOnce]
		resources: requests: storage: #config.#dataVolumeStorage
		if #config.configs.seafileDataVolume.storageClassName != _|_ {
			storageClassName: #config.configs.seafileDataVolume.storageClassName
		}
	}
}
