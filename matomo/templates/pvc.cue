
package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata:   #config.metadata & {
		name: #config.fullname
		if #config.persistence.annotations != _|_ && #config.persistence.annotations != {} {
			annotations: #config.persistence.annotations
		}
	}
	spec: {
		accessModes: [#config.persistence.accessMode]
		resources: requests: storage: #config.persistence.size
		
		if #config.persistence.storageClass != _|_ && #config.persistence.storageClass != null && #config.persistence.storageClass != "" {
			storageClassName: #config.persistence.storageClass
		}
	}
}
