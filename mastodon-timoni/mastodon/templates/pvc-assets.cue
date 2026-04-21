package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PvcAssets: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		namespace: #config.#namespace
		name: "\(#config.metadata.name)-assets"
		labels: #config.metadata.labels
		if #config.mastodon.persistence.assets.keepAfterDelete {
			annotations: "helm.sh/hook-delete-policy": "keep"
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.mastodon.persistence.assets.accessMode]
		if #config.mastodon.persistence.assets.resources != _|_ {
			resources: #config.mastodon.persistence.assets.resources
		}
		if #config.mastodon.persistence.assets.storageClassName != null {
			storageClassName: #config.mastodon.persistence.assets.storageClassName
		}
	}
}
