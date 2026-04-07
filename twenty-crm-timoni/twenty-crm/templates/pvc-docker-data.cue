package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServerDockerPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name: "\(#config.metadata.name)-docker-data"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "server"
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.server.dockerDataPersistence.accessModes
		resources: requests: storage: #config.server.dockerDataPersistence.size
		if #config.server.dockerDataPersistence.storageClass != "" {
			storageClassName: #config.server.dockerDataPersistence.storageClass
		}
	}
}
