package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigPVC: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-config"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "config"
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.persistence.config.accessModes
		resources: {
			requests: {
				storage: #config.persistence.config.storage
			}
		}
		if #config.persistence.config.storageClass != _|_ {
			storageClassName: #config.persistence.config.storageClass
		}
	}
}

#DataPVC: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-data"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "data"
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.persistence.data.accessModes
		resources: {
			requests: {
				storage: #config.persistence.data.storage
			}
		}
		if #config.persistence.data.storageClass != _|_ {
			storageClassName: #config.persistence.data.storageClass
		}
	}
}
