package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SharedPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-shared-data-pvc"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "shared"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.sharedDataPvc.accessModes
		resources: requests: storage: #config.sharedDataPvc.size
		if #config.sharedDataPvc.storageClassName != "" {
			storageClassName: #config.sharedDataPvc.storageClassName
		}
	}
}
