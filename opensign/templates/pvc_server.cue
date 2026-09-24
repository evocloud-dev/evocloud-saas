package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServerPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "opensign-files"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		accessModes: [#config.server.persistence.accessMode]
		if #config.server.persistence.storageClass != "" {
			storageClassName: #config.server.persistence.storageClass
		}
		resources: requests: storage: #config.server.persistence.size
	}
}
