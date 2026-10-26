package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config
	#name:   string
	#volume: #PersistenceVolume

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: #name
		if #volume.annotations != _|_ {
			annotations: #volume.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #volume.accessModes
		resources: requests: storage: #volume.size
		if #volume.storageClass != _|_ {
			storageClassName: #volume.storageClass
		}
	}
}

