package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#RedisPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name: "\(#config.metadata.name)-redis"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "redis"
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.redis.internal.persistence.accessModes
		resources: requests: storage: #config.redis.internal.persistence.size
		if #config.redis.internal.persistence.storageClass != "" {
			storageClassName: #config.redis.internal.persistence.storageClass
		}
	}
}
