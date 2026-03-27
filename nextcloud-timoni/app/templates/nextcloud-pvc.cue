package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// #NextcloudPVC is the literal conversion of nextcloud-pvc.yaml.
// The PVC is only emitted when:
//   - persistence.enabled == true
//   - persistence.hostPath is empty (not a hostPath volume)
//   - persistence.existingClaim is empty (no pre-created claim)
//
// Equivalent Helm condition:
//   {{- if and .Values.persistence.enabled
//              (not .Values.persistence.hostPath)
//              (not .Values.persistence.existingClaim) }}
#NextcloudPVC: corev1.#PersistentVolumeClaim & {
	#in: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"

	metadata: {
		name:      "\(#in.metadata.name)-nextcloud"
		namespace: #in.metadata.namespace

		labels: #in.metadata.labels & {
			for k, v in #in.persistence.labels {(k): v}
		}

		annotations: {
			// Keep the PVC when helm release is deleted (helm.sh/resource-policy: keep)
			"helm.sh/resource-policy": "keep"
			for k, v in #in.persistence.annotations {(k): v}
		}
	}

	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#in.persistence.accessMode]

		resources: requests: storage: #in.persistence.size

		// storageClass behaviour mirrors Helm:
		//   "-"        → storageClassName: ""  (disables dynamic provisioning)
		//   ""         → no storageClassName field (use cluster default)
		//   "<class>"  → storageClassName: "<class>"
		if #in.persistence.storageClass == "-" {
			storageClassName: ""
		}
		if #in.persistence.storageClass != "" && #in.persistence.storageClass != "-" {
			storageClassName: #in.persistence.storageClass
		}
	}
}
