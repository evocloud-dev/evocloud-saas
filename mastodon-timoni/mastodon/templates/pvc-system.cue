package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PvcSystem: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		namespace: #config.#namespace
		name: "\(#config.metadata.name)-system"
		labels: #config.metadata.labels
		if #config.mastodon.persistence.system.keepAfterDelete {
			annotations: "helm.sh/hook-delete-policy": "keep"
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.mastodon.persistence.system.accessMode]
		if #config.mastodon.persistence.system.resources != _|_ {
			resources: #config.mastodon.persistence.system.resources
		}
		if #config.mastodon.persistence.system.storageClassName != null {
			storageClassName: #config.mastodon.persistence.system.storageClassName
		}
	}
}
