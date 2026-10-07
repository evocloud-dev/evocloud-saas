package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.#dataClaim
		namespace: #config.metadata.namespace
		labels:    #config.#labels
		annotations: {
			if #config.persistence.retain {
				"helm.sh/resource-policy": "keep"
			}
			for k, v in #config.persistence.annotations {
				"\(k)": v
			}
		}
	}
	spec: {
		accessModes: [for mode in #config.persistence.accessModes {mode}]
		if #config.persistence.storageClass == "-" {
			storageClassName: ""
		}
		if #config.persistence.storageClass != "" && #config.persistence.storageClass != "-" {
			storageClassName: #config.persistence.storageClass
		}
		resources: requests: storage: #config.persistence.size
	}
}

