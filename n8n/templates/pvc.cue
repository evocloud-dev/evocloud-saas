package templates

import (
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
)

#PVCBuilder: corev1.#PersistentVolumeClaim & {
	_config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(_config.fullname)-data"
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
		if len(_config.persistence.annotations) > 0 {
			annotations: _config.persistence.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [_config.persistence.accessMode]
		if _config.persistence.storageClass != "" {
			storageClassName: _config.persistence.storageClass
		}
		resources: requests: (corev1.#ResourceStorage): resource.#Quantity & _config.persistence.size
	}
}
