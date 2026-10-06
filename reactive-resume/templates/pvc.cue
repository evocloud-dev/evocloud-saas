package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config

	_claimName: [
		if #config.persistence.existingClaim != "" {#config.persistence.existingClaim},
		#config.metadata.name,
	][0]

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      _claimName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.persistence.annotations != _|_ {
				#config.persistence.annotations
			}
			if #config.persistence.retain {
				"helm.sh/resource-policy": "keep"
			}
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [for m in #config.persistence.accessModes {corev1.#PersistentVolumeAccessMode & m}]
		if #config.persistence.storageClass == "-" {
			storageClassName: ""
		}
		if #config.persistence.storageClass != "" && #config.persistence.storageClass != "-" {
			storageClassName: #config.persistence.storageClass
		}
		resources: requests: (corev1.#ResourceStorage): #config.persistence.size
	}
}

