package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#BackendPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config._storageClaimName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "backend"
		}
	}
	spec: {
		accessModes: #config.backend.persistence.accessModes
		if #config.backend.persistence.storageClass != "" {
			storageClassName: #config.backend.persistence.storageClass
		}
		resources: requests: storage: #config.backend.persistence.size
	}
}
