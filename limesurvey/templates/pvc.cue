package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.#serviceName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.persistence.annotations) > 0 {
			annotations: #config.persistence.annotations
		}
		if len(#config.persistence.finalizers) > 0 {
			finalizers: #config.persistence.finalizers
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.persistence.accessModes
		resources: {
			requests: {
				storage: #config.persistence.size
			}
		}
		if #config.persistence.storageClass != null && #config.persistence.storageClass != "" {
			storageClassName: #config.persistence.storageClass
		}
		if len(#config.persistence.selectorLabels) > 0 {
			selector: {
				matchLabels: #config.persistence.selectorLabels
			}
		}
	}
}
