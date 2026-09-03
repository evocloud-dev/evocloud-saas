package templates

import (
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
)

#PVCData: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-\(#config.pvc.data.name)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		accessModes: [
			#config.pvc.data.accessMode,
		]
		if #config.pvc.data.storageClass != "" {
			storageClassName: #config.pvc.data.storageClass
		}
		resources: requests: storage: resource.#Quantity & #config.pvc.data.storage
	}
}

#PVCMysqlBackup: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-\(#config.pvc.mysqlBackup.name)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		accessModes: [
			#config.pvc.mysqlBackup.accessMode,
		]
		if #config.pvc.mysqlBackup.storageClass != "" {
			storageClassName: #config.pvc.mysqlBackup.storageClass
		}
		resources: requests: storage: resource.#Quantity & #config.pvc.mysqlBackup.storage
	}
}
