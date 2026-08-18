package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PVC: corev1.#PersistentVolumeClaim & {
	#config:  #Config
	#pvcName: string
	#pvcSpec: {
		enabled?:      bool
		storageClass:  string
		accessModes:   [...string]
		size:          string
		existingClaim: string
	}

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.fullname)-\(#pvcName)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "sonarqube"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: #pvcSpec.accessModes
		resources: requests: storage: #pvcSpec.size
		if #pvcSpec.storageClass != "" {
			storageClassName: #pvcSpec.storageClass
		}
	}
}
