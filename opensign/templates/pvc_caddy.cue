package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#CaddyDataPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "caddy-data"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		accessModes: [#config.caddy.persistence.accessMode]
		if #config.caddy.persistence.storageClass != "" {
			storageClassName: #config.caddy.persistence.storageClass
		}
		resources: requests: storage: #config.caddy.persistence.dataSize
	}
}

#CaddyConfigPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "caddy-config"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		accessModes: [#config.caddy.persistence.accessMode]
		if #config.caddy.persistence.storageClass != "" {
			storageClassName: #config.caddy.persistence.storageClass
		}
		resources: requests: storage: #config.caddy.persistence.configSize
	}
}
