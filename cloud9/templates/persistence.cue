package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#CodePVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.persistence.code.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.persistence.code.accessMode]
		resources: requests: storage: #config.persistence.code.size
	}
}

