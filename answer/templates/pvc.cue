package templates

import (
	corev1 "k8s.io/api/core/v1"
	resource "k8s.io/apimachinery/pkg/api/resource"
)

#PVC: {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.fullname)-data"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.persistence.annotations) > 0 {
			annotations: #config.persistence.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.persistence.accessMode]
		if #config.persistence.storageClass != "" {
			storageClassName: #config.persistence.storageClass
		}
		resources: {
			requests: {
				(corev1.#ResourceStorage): resource.#Quantity & #config.persistence.size
			}
		}
	}
}
