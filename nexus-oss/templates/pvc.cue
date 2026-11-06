package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "data"
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.persistence.data.accessMode]
		resources: requests: storage: #config.persistence.data.size
		if #config.persistence.data.storageClass != _|_ {
			storageClassName: #config.persistence.data.storageClass
		}
	}
}

