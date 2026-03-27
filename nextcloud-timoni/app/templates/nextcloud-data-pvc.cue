package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// #NextcloudDataPVC is the literal conversion of nextcloud-data-pvc.yaml.
// The PVC is only emitted when:
//   - persistence.enabled == true
//   - persistence.nextcloudData.enabled == true
//   - persistence.nextcloudData.hostPath is empty
//   - persistence.nextcloudData.existingClaim is empty
//
// Equivalent Helm condition:
//   {{- if and .Values.persistence.enabled
//              .Values.persistence.nextcloudData.enabled
//              (not .Values.persistence.nextcloudData.hostPath)
//              (not .Values.persistence.nextcloudData.existingClaim) }}
#NextcloudDataPVC: corev1.#PersistentVolumeClaim & {
	#in: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"

	metadata: {
		name:      "\(#in.metadata.name)-nextcloud-data"
		namespace: #in.metadata.namespace

		labels: #in.metadata.labels & {
			for k, v in #in.persistence.nextcloudData.labels {(k): v}
		}

		annotations: {
			// Keep the PVC when helm release is deleted (helm.sh/resource-policy: keep)
			"helm.sh/resource-policy": "keep"
			for k, v in #in.persistence.nextcloudData.annotations {(k): v}
		}
	}

	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#in.persistence.nextcloudData.accessMode]

		resources: requests: storage: #in.persistence.nextcloudData.size

		// storageClass behaviour mirrors Helm ternary:
		//   ternary "" . (eq "-" .)
		//   "-"        → storageClassName: ""  (disables dynamic provisioning)
		//   ""         → no storageClassName field (use cluster default)
		//   "<class>"  → storageClassName: "<class>"
		if #in.persistence.nextcloudData.storageClass == "-" {
			storageClassName: ""
		}
		if #in.persistence.nextcloudData.storageClass != "" && #in.persistence.nextcloudData.storageClass != "-" {
			storageClassName: #in.persistence.nextcloudData.storageClass
		}
	}
}
