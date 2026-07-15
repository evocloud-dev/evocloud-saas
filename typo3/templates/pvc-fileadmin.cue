package templates

import corev1 "k8s.io/api/core/v1"

#PVCFileadmin: corev1.#PersistentVolumeClaim & {
	#config:      #Config
	#persistence: #config.persistence.fileadmin

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-fileadmin"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#persistence.annotations) > 0 {
			annotations: #persistence.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #persistence.accessModes
		resources: #persistence.resources
		if #persistence.storageClassName != "" {
			storageClassName: #persistence.storageClassName
		}
	}
}
