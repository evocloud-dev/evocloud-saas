package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PVCBuilder: {
	_config:    #Config
	_name:      string
	_pvcConfig: #PersistenceItem

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(_config.fullname)-\(_name)"
		namespace: _config.namespace
		labels:    _config.selector.labels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [_pvcConfig.accessMode]
		resources: requests: storage: _pvcConfig.size
		if _pvcConfig.storageClass != "" {
			storageClassName: _pvcConfig.storageClass
		}
	}
}
