package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServerPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name: "\(#config.metadata.name)-server"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "server"
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.server.persistence.accessModes
		resources: requests: storage: #config.server.persistence.size
		if #config.server.persistence.storageClass != "" {
			storageClassName: #config.server.persistence.storageClass
		}
	}
}
