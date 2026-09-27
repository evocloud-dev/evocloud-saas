package templates

import (
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.claimName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.persistence.retain {
				"helm.sh/resource-policy": "keep"
			}
			if #config.persistence.annotations != _|_ {
				for k, v in #config.persistence.annotations {
					(k): v
				}
			}
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [for am in #config.persistence.accessModes {corev1.#PersistentVolumeAccessMode & am}]
		if #config.persistence.storageClass == "-" {
			storageClassName: ""
		}
		if #config.persistence.storageClass != "" && #config.persistence.storageClass != "-" {
			storageClassName: #config.persistence.storageClass
		}
		resources: requests: {
			storage: resource.#Quantity & #config.persistence.size
		}
	}
}

