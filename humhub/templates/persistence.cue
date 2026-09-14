package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.persistence.config.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: ["ReadWriteOnce"]
		resources: requests: storage: #config.persistence.config.size
	}
}

#AssetsPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.persistence.assets.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: ["ReadWriteOnce"]
		resources: requests: storage: #config.persistence.assets.size
	}
}

#ThemesPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.persistence.themes.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: ["ReadWriteOnce"]
		resources: requests: storage: #config.persistence.themes.size
	}
}

#ModulesPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.persistence.modules.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: ["ReadWriteOnce"]
		resources: requests: storage: #config.persistence.modules.size
	}
}

#UploadsPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      #config.persistence.uploads.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: ["ReadWriteOnce"]
		resources: requests: storage: #config.persistence.uploads.size
	}
}
