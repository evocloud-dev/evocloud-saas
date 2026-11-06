package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-data"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		accessModes: [for mode in #config.persistence.data.accessModes {mode}]
		resources: requests: storage: #config.persistence.data.size
		if #config.persistence.data.storageClass != _|_ {
			storageClassName: #config.persistence.data.storageClass
		}
	}
}

