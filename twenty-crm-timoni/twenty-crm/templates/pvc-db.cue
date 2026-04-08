package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DatabasePVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name: "\(#config.metadata.name)-db"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "db"
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.db.internal.persistence.accessModes
		resources: requests: storage: #config.db.internal.persistence.size
		if #config.db.internal.persistence.storageClass != "" {
			storageClassName: #config.db.internal.persistence.storageClass
		}
	}
}
