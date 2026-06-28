package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#MediaPVC: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-media"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "api"
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: ["ReadWriteOnce"]
		resources: requests: storage: #config.persistence.size
		if #config.persistence.storageClass != "" {
			storageClassName: #config.persistence.storageClass
		}
		if #config.persistence.storageClass == "" && #config.global.storageClass != "" {
			storageClassName: #config.global.storageClass
		}
	}
}
