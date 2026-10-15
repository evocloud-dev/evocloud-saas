package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config._claimName
		namespace: #config.metadata.namespace
		labels:    #config._labels
		if #config.persistence.retain || #config.persistence.annotations != _|_ {
			annotations: {
				if #config.persistence.retain {
					"helm.sh/resource-policy": "keep"
				}
				if #config.persistence.annotations != _|_ {
					for k, v in #config.persistence.annotations {
						"\(k)": v
					}
				}
			}
		}
	}
	spec: {
		accessModes: [for am in #config.persistence.accessModes {am}]
		if #config.persistence.storageClass == "-" {
			storageClassName: ""
		}
		if #config.persistence.storageClass != "" && #config.persistence.storageClass != "-" {
			storageClassName: #config.persistence.storageClass
		}
		resources: {
			requests: {
				storage: #config.persistence.size
			}
		}
	}
}

