package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQLPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "postgresql-data"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: ["ReadWriteOnce"]
		storageClassName: #config.postgresql.storage.storageClass
		resources: requests: storage: #config.postgresql.storage.size
	}
}
