package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#StoragePVC: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-storage"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.storage.local.annotations != _|_ {
			annotations: #config.storage.local.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.storage.local.accessMode]
		if #config.storage.local.storageClass != "" {
			storageClassName: #config.storage.local.storageClass
		}
		resources: requests: storage: #config.storage.local.size
	}
}
