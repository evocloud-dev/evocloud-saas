package templates

import (
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
)

#HubPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.#hubDataClaimName
		namespace: #config.metadata.namespace
		labels:    #config.#componentLabels & {#component: "hub-data"}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.hub.persistence.accessModes
		if #config.hub.persistence.storageClass != "" {
			storageClassName: #config.hub.persistence.storageClass
		}
		resources: requests: {
			(corev1.#ResourceStorage): resource.#Quantity & #config.hub.persistence.size
		}
	}
}
