package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#AppPublicPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.#fullname)-app-public"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.persistence.appPublic.accessModes
		resources: requests: storage: #config.persistence.appPublic.size
		if #config.persistence.appPublic.storageClassName != "" {
			storageClassName: #config.persistence.appPublic.storageClassName
		}
	}
}

#AppStoragePVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.#fullname)-app-storage"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.persistence.appStorage.accessModes
		resources: requests: storage: #config.persistence.appStorage.size
		if #config.persistence.appStorage.storageClassName != "" {
			storageClassName: #config.persistence.appStorage.storageClassName
		}
	}
}

#MysqlDataPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.#fullname)-mysql-data"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.persistence.mysqlData.accessModes
		resources: requests: storage: #config.persistence.mysqlData.size
		if #config.persistence.mysqlData.storageClassName != "" {
			storageClassName: #config.persistence.mysqlData.storageClassName
		}
	}
}

#RedisDataPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.#fullname)-redis-data"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #config.persistence.redisData.accessModes
		resources: requests: storage: #config.persistence.redisData.size
		if #config.persistence.redisData.storageClassName != "" {
			storageClassName: #config.persistence.redisData.storageClassName
		}
	}
}
