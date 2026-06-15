package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	#volumeName: string
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-\(#volumeName)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
		if #config.persistence[#volumeName].retain {
			annotations: "helm.sh/resource-policy": "keep"
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.persistence[#volumeName].accessMode]
		if #config.persistence[#volumeName].storageClass != _|_ {
			storageClassName: #config.persistence[#volumeName].storageClass
		}
		resources: requests: storage: #config.persistence[#volumeName].size
	}
}

#Volume: corev1.#Volume & {
	#cfg: #Config
	#volumeName: string
	name:    #volumeName
	if #cfg.persistence[#volumeName].emptyDir.enabled {
		emptyDir: {}
	}
	if !#cfg.persistence[#volumeName].emptyDir.enabled {
		persistentVolumeClaim: {
			claimName: "\(#cfg.metadata.name)-\(#volumeName)"
		}
	}
}