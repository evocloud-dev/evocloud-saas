package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServerPVC: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      *"\((#config.metadata.name))-server-storage" | string
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "server"
		}
		if #config.server.persistence.annotations != _|_ {
			annotations: #config.server.persistence.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.server.persistence.accessMode]
		resources: requests: storage: #config.server.persistence.size
		if #config.server.persistence.storageClass != "" {
			storageClassName: #config.server.persistence.storageClass
		}
		if #config.server.persistence.volumeName != "" {
			volumeName: #config.server.persistence.volumeName
		}
	}
}
