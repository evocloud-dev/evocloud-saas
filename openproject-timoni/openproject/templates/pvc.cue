package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "openproject"
		}
		if #config.persistence.annotations != _|_ {
			annotations: #config.persistence.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.persistence.accessModes
		if #config.persistence.storageClassName != "" {
			storageClassName: #config.persistence.storageClassName
		}
		resources: requests: storage: #config.persistence.size
	}
}
