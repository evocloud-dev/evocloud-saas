package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#LogsPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-logs"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.persistence.logs.accessModes
		resources: requests: storage: #config.persistence.logs.size
		if #config.persistence.logs.storageClass != "" {
			storageClassName: #config.persistence.logs.storageClass
		}
	}
}
