package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#MongoPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "mongo-data"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		accessModes: [#config.mongodb.persistence.accessMode]
		if #config.mongodb.persistence.storageClass != "" {
			storageClassName: #config.mongodb.persistence.storageClass
		}
		resources: requests: storage: #config.mongodb.persistence.size
	}
}
