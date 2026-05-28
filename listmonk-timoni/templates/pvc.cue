package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PVC: {
	#config: #Config
	#helpers: #Helpers

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#helpers.fullname)-uploads"
		namespace: #config.metadata.namespace
		labels:    #helpers.labels
		if #config.storage.annotations != _|_ {
			annotations: #config.storage.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.storage.accessMode]
		if #config.storage.storageClass != "" {
			storageClassName: #config.storage.storageClass
		}
		resources: requests: storage: #config.storage.size
	}
}
