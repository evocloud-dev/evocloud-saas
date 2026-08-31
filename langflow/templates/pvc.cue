// SPDX-License-Identifier: Apache-2.0
package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PVCBuilder: {
	_config:   #Config
	_fullname: string

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      _fullname
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: _config.persistence.accessModes
		if _config.persistence.storageClass != "" {
			storageClassName: _config.persistence.storageClass
		}
		resources: requests: storage: _config.persistence.size
	}
}
